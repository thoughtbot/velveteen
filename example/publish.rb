require "bunny"
require "json"

connection = Bunny.new
channel = connection.start.create_channel
exchange = channel.topic("velveteen-development", durable: true)

message_count = (ARGV.shift || 1).to_i

message_count.times do |i|
  exchange.publish(
    {job: i}.to_json,
    headers: {foo: "bar"},
    routing_key: "velveteen.fail.randomly",
    persistent: true
  )
end
