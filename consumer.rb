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
    @reporter = Reporter.new(name, connection.create_channel)
  end

  def subscribe
    puts "[#{num}] subscribing to #{name}"
    builds_queue.subscribe(ack: true, blocking: false, &method(:process)) 
  end

  def process(meta, payload)
    puts "[#{num}] received: #{payload}"
    reporter.message('job:test:start', payload)
    meta.ack
  rescue Exception => e
    puts e.message, e.backtrace
  end

  def builds_queue
    @builds_queue ||= builds_channel.queue(name, :durable => true)
  end

  def builds_channel
    @builds_channel ||= connection.create_channel.tap { |channel| channel.prefetch = 1 }
  end

  # def reporter
  #   @reporter ||= Reporter.new(name, connection.create_channel)
  # end
end

class Reporter
  attr_reader :name

  def initialize(name, channel)
    @name = name
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
