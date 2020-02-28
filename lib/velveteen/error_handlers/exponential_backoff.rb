module Velveteen
  module ErrorHandlers
    class ExponentialBackoff
      MAXIMUM_RETRIES = 25

      def self.call(**kwargs)
        new(**kwargs).call
      end

      def initialize(error:, message:, worker_class:)
        @error = error
        @message = message
        @worker_class = worker_class
      end

      def call
        Velveteen.logger.error(worker_class.queue_name) do
          "message '#{message.data}' failed - #{error.message}"
        end

        if retry?
          set_up_retry_queue
          publish_retry_message
        else
          set_up_error_queue
          publish_error_message
        end

        Config.channel.ack(message.delivery_info.delivery_tag, false)
      end

      private

      attr_reader :error, :message, :worker_class

      def set_up_error_queue
        queue = Config.channel.queue(
          "#{worker_class.queue_name}_error",
          durable: true,
        )

        queue.bind(Config.dlx_exchange, routing_key: worker_class.routing_key)
      end

      def retry?
        retry_count <= MAXIMUM_RETRIES
      end

      def retry_count
        message.headers.fetch("x-death", []).size + 1
      end

      def delay
        retry_count**2
      end

      def retry_routing_key
        "#{worker_class.routing_key}.#{delay}"
      end

      def set_up_retry_queue
        queue = Config.queue_class.new(
          Config.channel,
          "#{worker_class.queue_name}_retry_#{delay}",
          durable: true,
          arguments: {
            "x-dead-letter-exchange": Config.exchange_name,
            "x-dead-letter-routing-key": worker_class.routing_key,
            "x-message-ttl": delay * 1_000,
            "x-expires": delay * 1_000 * 2
          }
        )

        queue.bind(Config.exchange_name, routing_key: retry_routing_key)
      end

      def publish_retry_message
        Config.exchange.publish(
          message.body,
          routing_key: retry_routing_key,
          headers: message.headers,
        )
      end

      def publish_error_message
        Config.dlx_exchange.publish(
          message.body,
          routing_key: worker_class.routing_key,
          headers: message.headers,
        )
      end
    end
  end
end
