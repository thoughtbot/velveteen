require "velveteen"

Velveteen::Config.error_handler = Velveteen::ErrorHandlers::ExponentialBackoff
Velveteen::Config.exchange_name = "velveteen-development"

class PlaygroundWorker < Velveteen::Worker
  self.routing_key = "velveteen.general.development"
  # self.message_schema = "velveteen_general.json"
  self.rate_limit_key = "velveteen-general-development"

  def perform
    if message.data[:job].even? && rand > 0.5
      raise "Randomly failed"
    else
      puts "message '#{message.data}' worked - headers #{message.headers.inspect}"
    end
  end
end
