module Velveteen
  module Config
    class << self
      attr_accessor :connection, :error_handler
    end

    self.error_handler = ->(channel:, error:, message:) do
      channel.reject(message.delivery_info.delivery_tag, false)
      puts [error.message, error.backtrace]
    end
  end
end
