# balanced-spectator

Rack middleware to enqueue Balanced events to RabbitMQ

## Usage

#### Gemfile

```ruby
gem 'balanced-spectator', github: 'remear/balanced-spectator'
```

#### config.ru

```ruby
require 'bundler/setup'
Bundler.require(:default)

run Balanced::Spectator::Base.new
```

#### Options

Available options:

```authorized_ips``` - Array of strings of allowed request IPs. This is added to ```127.0.0.1``` and the current Balanced IPs.

```ignored_event_types``` - Array of strings of Balanced Event types to ignore and not pass to RabbitMQ.

```rabbitmq_queue_name``` - Name of the RabbitMQ queue to use. Defaults to ```balanced_event_incoming```. 

Example usage:

```ruby
run Balanced::Spectator::Base.new(
  authorized_ips: ['192.168.0.10', '192.168.0.11'],
  ignored_event_types: ['debit.succeeded', 'debit.failed', 'credit.succeeded'],
  rabbitmq_queue_name: 'balanced_event_incoming'
)
```


#### Run the application

While there are several ways to run a Rack application, a common way is to use Puma.

```bash
puma config.ru -p 9293
```

To daemonize:

```bash
puma -d config.ru -p 9293
```