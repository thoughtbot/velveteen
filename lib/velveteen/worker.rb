module Velveteen
  class Worker
    attr_reader :channel, :exchange, :queue

    class << self
      attr_accessor :exchange_name, :queue_name, :routing_key
    end

    def initialize(channel:)
      @channel = channel
      @exchange = channel.topic(self.class.exchange_name, durable: true)
      @queue = channel.queue(self.class.queue_name, durable: true)
      queue.bind(exchange, routing_key: self.class.routing_key)
    end

    def publish(*args)
      exchange.publish(*args)
    end
  end
end
