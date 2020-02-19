require "bunny"
require "json"
require "time"

module Velveteen
  class TokenBucket
    def initialize(per_minute:, key:)
      @key = key
      @per_minute = per_minute
      @queue = Config.channel.queue(
        key,
        durable: true,
        arguments: {
          "x-max-length" => 1,
        }
      )
      @queue.bind(Config.exchange, routing_key: key)
    end

    def produce
      Config.exchange.publish(
        Time.now.utc.iso8601,
        routing_key: key,
      )
    end

    def take
      loop do
        delivery_info, _, _ = @queue.pop(manual_ack: true)

        if delivery_info
          Config.channel.basic_ack(delivery_info.delivery_tag.to_i)
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

    attr_reader :expiration, :key
  end
end
