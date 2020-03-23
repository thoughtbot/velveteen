require "timeout"
require "velveteen/take_token"

module Velveteen
  class HandleMessage
    def self.call(**kwargs)
      new(**kwargs).call
    end

    def initialize(message:, worker_class:)
      @message = message
      @worker_class = worker_class
    end

    def call
      rate_limit
      perform_work
      acknowledge_message
    rescue => error
      handle_error(error)
    end

    private

    attr_reader :message, :worker_class

    def rate_limit
      if worker.rate_limited?
        TakeToken.call(worker: worker)
      end
    end

    def worker
      @worker ||= worker_class.new(message: message)
    end

    def perform_work
      Timeout.timeout(Config.worker_timeout, WorkerTimeout, timeout_message) do
        worker.perform
      end
    end

    def timeout_message
      "timed out after #{Config.worker_timeout}s"
    end

    def acknowledge_message
      Config.channel.ack(message.delivery_info.delivery_tag)
    end

    def handle_error(error)
      Config.error_handler.call(
        error: error,
        message: message,
        worker_class: worker_class
      )
    end
  end
end
