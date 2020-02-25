require "velveteen/config"
require "velveteen/token_bucket"

module Velveteen
  module Commands
    class RateLimit
      def self.call(**kwargs)
        new(**kwargs).call
      end

      def initialize(argv:, stdout:)
        @queue_name = argv.shift
        @per_minute = argv.shift.to_f
        @stdout = stdout
      end

      def call
        stdout.puts "rate limiting #{queue_name} at #{per_minute} per minute"
        stdout.puts "CTRL+C to stop"
        token_bucket = TokenBucket.new(
          per_minute: per_minute,
          queue_name: queue_name,
        )

        loop do
          token_bucket.produce
          sleep token_bucket.duration
        end
      end

      private

      attr_reader :config, :per_minute, :queue_name, :stdout
    end
  end
end
