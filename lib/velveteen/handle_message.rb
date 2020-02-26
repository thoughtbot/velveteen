require "velveteen/take_token"

module Velveteen
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
        worker_class: worker_class,
      )
    end
  end
end
