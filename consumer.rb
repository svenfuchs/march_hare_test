require 'bundler'
Bundler.setup
require 'march_hare'

name = 'builds.2'
puts "subscribing to #{name}"

connection = MarchHare.connect user: 'travis', password: 'travis', vhost: 'travis'

channel = connection.create_channel.tap { |channel| channel.prefetch = 1 }
queue = channel.queue(name, :durable => true)

1.upto(3) do |i|
  queue.subscribe(ack: true, blocking: false) do |meta, payload|
    puts "[#{i}] received: #{payload}"
    meta.ack
  end
end
 
