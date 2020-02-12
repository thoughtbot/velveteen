require "bunny"
require "json"

module Velveteen
  class CLI
    def initialize(argv:, stdout: $stdout)
      # TODO: Think about this interface and how to make it more friendly
      @worker_file = argv.shift
      @worker_class_name = argv.shift
      @stdout = stdout
    end

    def call
      stdout.sync = true

      # TODO: What settings need/should be set here?
      connection = Bunny.new
      connection.start

      channel = connection.create_channel
      channel.prefetch(1)

      stdout.puts " [*] Waiting for messages. To exit press CTRL+C"

      require File.expand_path(worker_file)
      worker_class = Object.const_get(worker_class_name)

      begin
        worker = worker_class.new(channel: channel)

        worker.queue.subscribe(manual_ack: true, block: true) do |delivery_info, _properties, body|
          data = JSON.parse(body, symbolize_names: true)
          worker.perform(
            Message.new(
              data: data[:data],
              ancillary: data[:ancillary],
            )
          )

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
