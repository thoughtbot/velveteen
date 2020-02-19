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
        channel = Config.connection.create_channel
        channel.prefetch(1)

        stdout.puts " [*] Waiting for messages. To exit press CTRL+C"

        require File.expand_path(worker_file)
        worker_class = Object.const_get(worker_class_name)

        RunWorker.new(channel: channel, worker_class: worker_class).call
      end

      private

      attr_reader :stdout, :worker_file, :worker_class_name
    end

    class RunWorker
      def initialize(channel:, worker_class:)
        @channel = channel
        @worker_class = worker_class
      end

      def call
        exchange = channel.topic(worker_class.exchange_name, durable: true)
        queue = channel.queue(worker_class.queue_name, durable: true)
        queue.bind(exchange, routing_key: worker_class.routing_key)

        queue.subscribe(manual_ack: true) do |delivery_info, properties, body|
          HandleMessage.call(
            body: body,
            exchange: exchange,
            properties: properties,
            worker_class: worker_class,
          )
          channel.ack(delivery_info.delivery_tag)
        end

        loop { sleep 5 }
      end

      private

      attr_reader :channel, :worker_class
    end

    class HandleMessage
      def self.call(worker_class:, exchange:, properties:, body:)
        json_message = JSON.parse(body, symbolize_names: true)

        message = Message.new(data: json_message, metadata: properties.headers)

        worker = worker_class.new(exchange: exchange, message: message)

        if worker.rate_limited?
          TakeToken.call(worker: worker)
        end

        worker.perform
      rescue JSON::ParserError => e
        raise InvalidMessage.new(e)
      end
    end
  end

  class TakeToken
    def self.call(worker:)
      # TODO: this is too much info for consuming
      token_bucket = TokenBucket.new(
        # TODO: do not create a channel each time
        channel: Config.connection.create_channel,
        exchange_name: worker.exchange_name,
        per_minute: 600, # TODO: pull this from config
        key: worker.rate_limit_key,
      )
      token_bucket.take
    end
  end
end
