require "bunny"
require "json"
require "time"

class TokenBucket
  EXCHANGE_NAME = "foo"

  def initialize(channel:, per_minute:, key:)
    @channel = channel
    @key = key
    @per_minute = per_minute
    @exchange = @channel.topic(EXCHANGE_NAME, durable: true)
    @queue = @channel.queue(
      key,
      durable: true,
      arguments: {
        "x-max-length" => 1,
      }
    )
    @queue.bind(exchange, routing_key: key)
  end

  def produce
    exchange.publish(
      Time.now.utc.iso8601,
      routing_key: key,
    )
  end

  def take
    loop do
      delivery_info, _, _ = @queue.pop(manual_ack: true)

      if delivery_info
        @channel.basic_ack(delivery_info.delivery_tag.to_i)
        break
      end

      sleep duration
    end
  end

  def duration
    60.0 / @per_minute
  end

  def to_s
    "<TokenBucket:#{key}>"
  end

  private

  attr_reader :exchange, :expiration, :key
end
