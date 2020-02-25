require "timecop"

require "velveteen/token_bucket"

BunnyMock.use_bunny_queue_pop_api = true
BUNNY_CONNECTION = BunnyMock.new.start

RSpec.describe Velveteen::TokenBucket do
  describe "#duration" do
    it "returns the duration of a token" do
      token_bucket = described_class.new(queue_name: "foo", per_minute: 120)

      expect(token_bucket.duration).to eq 0.5
    end
  end

  describe "#produce" do
    it "publishes a token to the queue" do
      new_time = Time.local(2019, 9, 1, 12, 0, 0)
      Timecop.freeze(new_time) do
        queue_name = "test_bucket"
        per_minute = 10
        queue = Velveteen::Config.channel.queue(queue_name)
        token_bucket = described_class.new(
          queue_name: queue_name,
          per_minute: per_minute,
        )

        token_bucket.produce

        expect(queue.message_count).to eq(1)
        payload = queue.pop
        expect(queue.message_count).to eq(0)
        expect(payload[2]).to eq(new_time.utc.iso8601)
      end
    end
  end

  describe "#take" do
    it "blocks until a token is available" do
      delivery_info = double(delivery_tag: "1")
      per_minute = 10
      queue_name = "test_bucket"
      queue = double(BunnyMock::Queue, bind: true)
      channel = double(BunnyMock::Channel, basic_ack: true, queue: queue, topic: true)
      allow(Velveteen::Config).to receive(:channel).and_return(channel)
      token_bucket = described_class.new(
        queue_name: queue_name,
        per_minute: per_minute,
      )
      allow(queue).to receive(:pop).and_return([nil, nil, nil], [delivery_info, {}, "Token"])
      allow(channel).to receive(:basic_ack)
      allow(token_bucket).to receive(:sleep)

      token_bucket.take

      expect(queue).to have_received(:pop).twice
      expect(token_bucket).to have_received(:sleep).once.with(60.0 / per_minute)
    end
  end
end
