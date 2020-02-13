require "velveteen/commands/rate_limit"
require "velveteen/worker"

RSpec.describe Velveteen::Commands::RateLimit do
  it do
    argv = %w[
      test-velveteen
      test-rate-limit-key
      300
    ]
    config = double(connection: BunnyMock.new.start)
    rate_limit = described_class.new(
      argv: argv,
      config: config,
      stdout: StringIO.new,
    )
    token_bucket = instance_double(TokenBucket, produce: true, duration: 0.2)
    allow(TokenBucket).to receive(:new).and_return(token_bucket)
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

    expect(TokenBucket).to have_received(:new).with(
      channel: anything,
      exchange_name: "test-velveteen",
      key: "test-rate-limit-key",
      per_minute: 300,
    )
    expect(token_bucket).to have_received(:produce).twice
    expect(rate_limit).to have_received(:sleep).with(0.2).twice
  end
end
