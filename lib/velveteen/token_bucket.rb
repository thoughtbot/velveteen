require "bunny"
require "json"
require "time"

module Velveteen
  class TokenBucket
    def initialize(per_minute:, queue_name:)
      @queue_name = queue_name
      @per_minute = per_minute
      @queue = Config.channel.queue(
        queue_name,
        durable: true,
        arguments: {
          "x-max-length" => 1,
        }
      )
    end

    def produce
      queue.publish(
        Time.now.utc.iso8601,
        routing_key: queue_name,
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
      "<TokenBucket:#{queue_name}>"
    end

    private

    attr_reader :expiration, :queue_name, :queue
  end
end
