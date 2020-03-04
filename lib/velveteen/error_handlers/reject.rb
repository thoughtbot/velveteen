module Velveteen
  module ErrorHandlers
    class Reject
      def self.call(error:, message:, worker_class:)
        Config.channel.reject(message.delivery_info.delivery_tag, false)
        Velveteen.logger.error(error.message)
        Velveteen.logger.debug(error.backtrace)
      end
    end
  end
end
