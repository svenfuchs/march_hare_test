require 'bundler'
Bundler.setup
require 'march_hare'

name = "builds.#{ARGV[0] || 0}"
connection = MarchHare.connect user: 'travis', password: 'travis', vhost: 'travis'
channel = connection.create_channel
exchange = channel.direct('', durable: true, auto_delete: false)

loop do
  sleep 0.5
  data = rand.to_s
  begin
    exchange.publish(data, routing_key: name, properties: { message_id:rand(100000000000).to_s })
    puts "Published #{data} to #{name}"
  rescue Exception => e
    puts e.message, e.backtrace
  end
end


