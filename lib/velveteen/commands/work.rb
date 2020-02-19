module Velveteen
  module Commands
    class Work
      def self.call(*args)
        new(*args).call
      end

      def initialize(argv:, stdout:)
        # TODO: Think about this interface and how to make it more friendly
        if argv.length < 2
          warn "expected: velveteen work path/to/worker.rb WorkerClassName"
          exit 1
        end
        @worker_file = argv.shift
        @worker_class_name = argv.shift
        @stdout = stdout
      end

      def call
        stdout.puts " [*] Waiting for messages. To exit press CTRL+C"

        require File.expand_path(worker_file)
        worker_class = Object.const_get(worker_class_name)

        RunWorker.new(worker_class: worker_class).call
      end

      private

      attr_reader :stdout, :worker_file, :worker_class_name
    end

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

    class ParseMessage
      def self.call(body:, delivery_info:, properties:)
        data = JSON.parse(body, symbolize_names: true)

        Message.new(
          body: body,
          data: data,
          delivery_info: delivery_info,
          metadata: properties.headers,
          properties: properties,
        )
      rescue JSON::ParserError => e
        raise InvalidMessage.new(e)
      end
    end

    class HandleMessage
      def self.call(message:, worker_class:)
        worker = worker_class.new(message: message)

        if worker.rate_limited?
          TakeToken.call(worker: worker)
        end

        worker.perform

        Config.channel.ack(message.delivery_info.delivery_tag)
      rescue => error
        Config.error_handler.call(
          error: error,
          message: message,
        )
      end
    end
  end

  class TakeToken
    def self.call(worker:)
      token_bucket = TokenBucket.new(
        per_minute: 600, # TODO: pull this from config
        key: worker.rate_limit_key,
      )
      token_bucket.take
    end
  end
end
