require "velveteen"

Velveteen::Config.error_handler = Velveteen::ErrorHandlers::ExponentialBackoff
Velveteen::Config.exchange_name = "velveteen_development"

class RandomlyFail < Velveteen::Worker
  self.routing_key = "velveteen.fail.randomly"
  # self.message_schema = "velveteen_general.json"
  self.rate_limit_queue = "velveteen_general_tokens"

  def perform
    if message.data[:job].even? && rand > 0.5
      raise "Randomly failed"
    else
      puts "message '#{message.data}' worked - headers #{message.headers.inspect}"
    end
  end
end
