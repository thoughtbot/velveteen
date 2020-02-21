require "velveteen/error_handlers"

module Velveteen
  module Config
    class << self
      attr_accessor :connection, :error_handler, :exchange_name, :queue_class
    end

    def self.channel
      @channel ||= connection.create_channel.tap do |channel|
        channel.prefetch(1)
      end
    end

    def self.exchange
      Config.channel.topic(exchange_name, durable: true)
    end

    def self.dlx_exchange
      @dlx_exchange ||= Config.channel.topic(
        "#{exchange_name}_dlx",
        durable: true
      )
    end

    self.error_handler = ErrorHandlers::Reject
  end
end
