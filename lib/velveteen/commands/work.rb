module Velveteen
  module Commands
    class Work
      def initialize(argv:, stdout:)
        # TODO: Think about this interface and how to make it more friendly
        @worker_file = argv.shift
        @worker_class_name = argv.shift
        @stdout = stdout
      end

      def call
        # TODO: What settings need/should be set here?
        connection = Bunny.new
        connection.start

        channel = connection.create_channel
        channel.prefetch(1)

        stdout.puts " [*] Waiting for messages. To exit press CTRL+C"

        require File.expand_path(worker_file)
        worker_class = Object.const_get(worker_class_name)

        begin
          exchange = channel.topic(worker_class.exchange_name, durable: true)
          queue = channel.queue(worker_class.queue_name, durable: true)
          queue.bind(exchange, routing_key: worker_class.routing_key)

          queue.subscribe(manual_ack: true, block: true) do |delivery_info, _properties, body|
            worker_class.new(
              exchange: exchange,
              message_body: body,
            ).perform

            channel.ack(delivery_info.delivery_tag)
          end
        rescue Interrupt => _
          connection.close
        end
      end

      private

      attr_reader :stdout, :worker_file, :worker_class_name
    end
  end
end
