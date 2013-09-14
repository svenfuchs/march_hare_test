require 'bundler'
Bundler.setup
require 'march_hare'

name = "builds.#{ARGV[0] || 0}"

class Consumer
  attr_reader :connection, :name, :num, :reporter

  def initialize(connection, name, num)
    @connection = connection
    @name = name
    @num = num
    # Creating the reporter early (so it is not created within the `process`
    # callback) will throw "Attempt to use closed channel" after rabbitmq-server
    # has been restarted: https://gist.github.com/svenfuchs/e5e5717977d973df6521
    # @reporter = Reporter.new(connection.create_channel)
  end

  def subscribe
    puts "[#{num}] subscribing to #{name}"
    builds_queue.subscribe(ack: true, blocking: false, &method(:process)) 
  end

  def process(meta, payload)
    puts "[#{num}] received: #{payload}"
    reporter.message('job:test:start', payload)
  rescue Exception => e
    puts e.message, e.backtrace
  ensure
    meta.ack
  end

  def builds_queue
    @builds_queue ||= builds_channel.queue(name, :durable => true)
  end

  def builds_channel
    @builds_channel ||= connection.create_channel.tap { |channel| channel.prefetch = 1 }
  end

  # This is what travis-worker does. Using this, march_hare would not reconnect, but
  # also not report an exception.
  def reporter
    @reporter ||= Reporter.new(connection.create_channel)
  end
end

class Reporter
  def initialize(channel)
    @exchange = channel.exchange('reporting', type: :topic, durable: true)
  end

  def message(event, data)
    puts "reporting #{event}: #{data}"
    @exchange.publish(data, properties: { type: event }, routing_key: 'reporting.jobs.builds')
  end
end

connection = MarchHare.connect user: 'travis', password: 'travis', vhost: 'travis'
 
1.upto(3) do |i|
  Consumer.new(connection, name, i).subscribe
end

sleep
