module Velveteen
  class TakeToken
    def self.call(worker:)
      token_bucket = TokenBucket.new(
        per_minute: 600,
        queue_name: worker.rate_limit_queue
      )
      token_bucket.take
    end
  end
end
