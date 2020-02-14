require "velveteen/config"
require "velveteen/token_bucket"

module Velveteen
  module Commands
    class RateLimit
      def self.call(*args)
        new(*args).call
      end

      def initialize(argv:, stdout:)
        @exchange_name = argv.shift
        @routing_key = argv.shift
        @per_minute = argv.shift.to_f
        @stdout = stdout
      end

      def call
        stdout.puts "rate limiting #{routing_key} at #{per_minute} per minute"
        stdout.puts "CTRL+C to stop"
        channel = Config.connection.create_channel
        token_bucket = TokenBucket.new(
          channel: channel,
          exchange_name: exchange_name,
          per_minute: per_minute,
          key: routing_key,
        )

        loop do
          token_bucket.produce
          sleep token_bucket.duration
        end
      end

      private

      attr_reader :config, :exchange_name, :per_minute, :routing_key, :stdout
    end
  end
end
