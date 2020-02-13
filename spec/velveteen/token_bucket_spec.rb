require "timecop"
require "spec_helper"

require "velveteen/token_bucket"

BunnyMock.use_bunny_queue_pop_api = true
BUNNY_CONNECTION = BunnyMock.new.start

RSpec.describe TokenBucket do
  describe "#duration" do
    it "returns the duration of a token" do
      channel = BUNNY_CONNECTION.channel
      token_bucket = TokenBucket.new(
        channel: channel,
        key: "foo",
        per_minute: 120,
      )

      expect(token_bucket.duration).to eq 0.5
    end
  end

  describe "#produce" do
    it "publishes messages with the correct key and routing key" do
      new_time = Time.local(2019, 9, 1, 12, 0, 0)
      Timecop.freeze(new_time) do
        key = "token-bucket"
        per_minute = 10
        connection = BUNNY_CONNECTION
        channel = connection.channel
        queue = channel.queue(key)
        token_bucket = TokenBucket.new(
          channel: channel,
          key: key,
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
      key = "test-key"
      queue = double(BunnyMock::Queue, bind: true)
      channel = double(BUNNY_CONNECTION.start.channel, basic_ack: true, queue: queue, topic: true)
      token_bucket = TokenBucket.new(
        channel: channel,
        key: key,
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
