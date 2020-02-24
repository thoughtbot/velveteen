module Velveteen
  class TakeToken
    def self.call(worker:)
      token_bucket = TokenBucket.new(
        per_minute: 600, # TODO: pull this from config
        key: worker.rate_limit_key,
      )
      token_bucket.take
    end
  end
end
