require "velveteen"

class PlaygroundWorker < Velveteen::Worker
  self.exchange_name = "velveteen-development"
  self.queue_name = "velveteen_general_development"
  self.routing_key = "velveteen.general.development"
  # self.message_schema = "velveteen_general.json"
  # self.rate_limit_key = "velveteen-general-development"

  def perform
    if message.data[:job].even? && rand > 0.5
      raise "Randomly failed"
    else
      puts "message '#{message.data[:job]}' worked - metadata #{message.metadata.inspect}"
    end
  end
end
