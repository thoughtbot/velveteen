require "velveteen/handle_message"
require "velveteen/parse_message"

module Velveteen
  class RunWorker
    def initialize(worker_class:)
      @worker_class = worker_class
    end

    def call
      queue = Config.channel.queue(worker_class.queue_name, durable: true)
      queue.bind(Config.exchange, routing_key: worker_class.routing_key)

      queue.subscribe(manual_ack: true) do |delivery_info, properties, body|
        message = ParseMessage.call(
          body: body,
          delivery_info: delivery_info,
          properties: properties,
        )
        HandleMessage.call(
          message: message,
          worker_class: worker_class,
        )
      end

      loop { sleep 5 }
    end

    private

    attr_reader :worker_class
  end
end
