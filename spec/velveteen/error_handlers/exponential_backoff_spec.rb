require "velveteen/error_handlers/exponential_backoff"

RSpec.describe Velveteen::ErrorHandlers::ExponentialBackoff do
  it "publishes the message to a retry queue" do
    exchange = Velveteen::Config.exchange
    allow(exchange).to receive(:publish)
    error = Exception.new
    message = Velveteen::Message.new(
      body: "foo-body",
      delivery_info: double(delivery_tag: "foo-tag"),
      headers: {},
    )
    worker = instance_double(
      Velveteen::Worker,
      queue_name: "foo_queue",
      routing_key: "foo.key",
    )
    allow(Velveteen::Config.queue_class).to receive(:new).and_call_original

    described_class.call(error: error, message: message, worker: worker)

    expect(Velveteen::Config.queue_class).to have_received(:new).with(
      Velveteen::Config.channel,
      "foo_queue_retry_1",
      durable: true,
      arguments: {
        "x-dead-letter-exchange": Velveteen::Config.exchange_name,
        "x-dead-letter-routing-key": "foo.key",
        "x-message-ttl": 1_000,
        "x-expires": 2_000,
      }
    )
    expect(exchange).to have_received(:publish).with(
      "foo-body",
      routing_key: "foo.key.1",
      headers: message.headers,
    )
  end

  it "will retry up to the maximum count" do
    exchange = Velveteen::Config.exchange
    allow(exchange).to receive(:publish)
    error = Exception.new
    stub_const(
      "Velveteen::ErrorHandlers::ExponentialBackoff::MAXIMUM_RETRIES",
      5,
    )
    message = Velveteen::Message.new(
      body: "foo-body",
      delivery_info: double(delivery_tag: "foo-tag"),
      headers: {"x-death" => Array.new(4)},
    )
    worker = instance_double(
      Velveteen::Worker,
      queue_name: "foo_queue",
      routing_key: "foo.key",
    )
    allow(Velveteen::Config.queue_class).to receive(:new).and_call_original

    described_class.call(error: error, message: message, worker: worker)

    expect(Velveteen::Config.queue_class).to have_received(:new).with(
      Velveteen::Config.channel,
      "foo_queue_retry_25",
      durable: true,
      arguments: {
        "x-dead-letter-exchange": Velveteen::Config.exchange_name,
        "x-dead-letter-routing-key": "foo.key",
        "x-message-ttl": 25_000,
        "x-expires": 50_000,
      }
    )
    expect(exchange).to have_received(:publish).with(
      "foo-body",
      routing_key: "foo.key.25",
      headers: message.headers,
    )
  end

  it "does not retry after the maximum count has been reached" do
    exchange = Velveteen::Config.exchange
    allow(exchange).to receive(:publish)
    error = Exception.new
    message = Velveteen::Message.new(
      body: "foo-body",
      delivery_info: double(delivery_tag: "foo-tag"),
      headers: {"x-death" => Array.new(described_class::MAXIMUM_RETRIES)},
    )
    worker = instance_double(
      Velveteen::Worker,
      queue_name: "foo_queue",
      routing_key: "foo.key",
    )
    error_queue = Velveteen::Config.channel.queue("foo_queue_error")
    allow(Velveteen::Config.queue_class).to receive(:new).and_call_original

    described_class.call(error: error, message: message, worker: worker)

    error_message = error_queue.pop
    expect(error_message).not_to eq([nil, nil, nil])
    expect(Velveteen::Config.queue_class).not_to have_received(:new)
    expect(exchange).not_to have_received(:publish)
  end
end
