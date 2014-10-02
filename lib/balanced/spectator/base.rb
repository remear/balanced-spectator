require 'rack'
require 'json'
require 'ipaddr'
require "bunny"

module Balanced
  module Spectator
    class Base
      TRUSTED_PROXIES = /^127\.0\.0\.1$|^(10|172\.(1[6-9]|2[0-9]|30|31)|192\.168)\./i
      DEFAULT_AUTHORIZED_IPS = ['127.0.0.1', '50.18.199.26', '50.18.204.103']
      REJECTED_RESPONSE = [403, {'Content-Type' => 'text/html'}, ['Unauthorized']]      
      REQUEST_NOT_JSON_RESPONSE = [403,
                                    {"Content-Type" => "text/html"},
                                    ['Request must be application/json']]
      DEFAULT_RABBITMQ_QUEUE_NAME = 'balanced_event_incoming'
      DEFAULT_RABBITMQ_HOST = 'localhost'
      DEFAULT_RABBITMQ_PORT = 5672
      DEFAULT_RABBITMQ_SSL = false
      DEFAULT_RABBITMQ_VHOST = '/'
      DEFAULT_RABBITMQ_USER = 'guest'
      DEFAULT_RABBITMQ_PASS = 'guest'

      def initialize(options={})
        if options[:authorized_ips]
          @authorized_ips = DEFAULT_AUTHORIZED_IPS | options[:authorized_ips]
        else
          @authorized_ips = DEFAULT_AUTHORIZED_IPS
        end
        @ignored_event_types = options[:authorized_ips] ? options[:authorized_ips] : []
        rabbitmq_queue_name = options[:rabbitmq_queue_name] ?
                                options[:rabbitmq_queue_name] : DEFAULT_RABBITMQ_QUEUE_NAME
        rabbitmq_host = options[:rabbitmq_host] ?
                          options[:rabbitmq_host] : DEFAULT_RABBITMQ_HOST
        rabbitmq_port = options[:rabbitmq_port] ?
                          options[:rabbitmq_port] : DEFAULT_RABBITMQ_PORT
        rabbitmq_ssl = options[:rabbitmq_ssl] ?
                          options[:rabbitmq_ssl] : DEFAULT_RABBITMQ_SSL
        rabbitmq_vhost = options[:rabbitmq_vhost] ?
                          options[:rabbitmq_vhost] : DEFAULT_RABBITMQ_VHOST
        rabbitmq_user = options[:rabbitmq_user] ?
                          options[:rabbitmq_user] : DEFAULT_RABBITMQ_USER
        rabbitmq_pass = options[:rabbitmq_pass] ?
                          options[:rabbitmq_pass] : DEFAULT_RABBITMQ_PASS

        rabbit_conn = Bunny.new(
            :host => rabbitmq_host,
            :port => rabbitmq_port,
            :ssl => rabbitmq_ssl,
            :vhost => rabbitmq_vhost,
            :user => rabbitmq_user,
            :pass => rabbitmq_pass
            )
        rabbit_conn.start
        ch = rabbit_conn.create_channel
        @rabbit_queue = ch.queue(rabbitmq_queue_name, :durable => true)
      end

      def process_payload(payload, env)
        if ! @ignored_event_types.include?(payload['type'])
          @rabbit_queue.publish(payload.to_json, :persistent => true)
        end
      end
    
      def call(env)
        request = Rack::Request.new env
        unless authorized_ip?(env)
          return REJECTED_RESPONSE
        end
        return REJECTED_RESPONSE if !request.env['HTTP_USER_AGENT'].include?('balanced/hooker')
        return REQUEST_NOT_JSON_RESPONSE if request.env['CONTENT_TYPE'] != 'application/json'

        begin
          payload = JSON.parse request.body.read
          raise "Empty Payload" if payload.nil?

          process_payload(payload, env)

          [200, {"Content-Type" => "text/html"}, ['Success']]
        rescue Exception => e
          [400, {"Content-Type" => "text/html"}, ["There was a problem in the JSON submitted. #{e.message}"]]
        end
      end


      private
        def authorized_ip?(env)
          @authorized_ips.include?(remote_ip(env))
        end
  
        # Modified from Rails actionpack.
        # Determines originating IP address.  REMOTE_ADDR is the standard
        # but will fail if the user is behind a proxy.  HTTP_CLIENT_IP and/or
        # HTTP_X_FORWARDED_FOR are set by proxies so check for these if
        # REMOTE_ADDR is a proxy.  HTTP_X_FORWARDED_FOR may be a comma-
        # delimited list in the case of multiple chained proxies; the last
        # address which is not trusted is the originating IP.
        def remote_ip(env)
          remote_addr_list = env['REMOTE_ADDR'] && env['REMOTE_ADDR'].scan(/[^,\s]+/)

          unless remote_addr_list.size == 0
            not_trusted_addrs = remote_addr_list.reject {|addr| addr =~ TRUSTED_PROXIES}
            return not_trusted_addrs.first unless not_trusted_addrs.empty?
          end
          remote_ips = env['HTTP_X_FORWARDED_FOR'] && env['HTTP_X_FORWARDED_FOR'].split(',')
    
          if env.include? 'HTTP_CLIENT_IP'
            return env['HTTP_CLIENT_IP']
          end

          if remote_ips
            while remote_ips.size > 1 && TRUSTED_PROXIES =~ remote_ips.last.strip
              remote_ips.pop
            end

            return remote_ips.last.strip
          end

          env['REMOTE_ADDR']
        end
    end
  end
end
