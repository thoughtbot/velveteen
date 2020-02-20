module Velveteen
  module ErrorHandlers
    class Reject
      def self.call(error:, message:, worker:)
        Config.channel.reject(message.delivery_info.delivery_tag, false)
        puts [error.message, error.backtrace]
      end
    end
  end
end
