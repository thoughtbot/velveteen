require "velveteen/commands/rate_limit"
require "velveteen/worker"

RSpec.describe Velveteen::Commands::RateLimit do
  it "produces tokens at an interval until interrupted" do
    argv = %w[
      test_rate_limit_queue
      300
    ]
    rate_limit = described_class.new(
      argv: argv,
      stdout: StringIO.new,
    )
    token_bucket = instance_double(
      Velveteen::TokenBucket,
      produce: true,
      duration: 0.2,
    )
    allow(Velveteen::TokenBucket).to receive(:new).and_return(token_bucket)
    call_count = 0
    allow(rate_limit).to receive(:sleep) do
      call_count += 1
      if call_count >= 2
        raise Interrupt
      end
    end

    expect {
      rate_limit.call
    }.to raise_error(Interrupt)

    expect(Velveteen::TokenBucket).to have_received(:new).with(
      queue_name: "test_rate_limit_queue",
      per_minute: 300,
    )
    expect(token_bucket).to have_received(:produce).twice
    expect(rate_limit).to have_received(:sleep).with(0.2).twice
  end
end
