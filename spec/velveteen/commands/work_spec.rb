require "velveteen/commands/work"
require "velveteen/worker"

RSpec.describe Velveteen::Commands::HandleMessage do
  class TestWorker < Velveteen::Worker
    def perform
    end
  end

  it "invokes the given worker" do
    worker_instance = instance_double(
      TestWorker,
      perform: true,
      rate_limited?: false,
    )
    allow(TestWorker).to receive(:new).and_return(worker_instance)
    allow(Velveteen::TakeToken).to receive(:call)
    message = instance_double(
      Velveteen::Message,
      delivery_info: double(delivery_tag: double),
    )

    described_class.call(
      message: message,
      worker_class: TestWorker,
    )

    expect(Velveteen::TakeToken)
      .not_to have_received(:call).with(worker: worker_instance)
    expect(worker_instance).to have_received(:perform)
  end

  it "supports rate limiting" do
    worker_instance = instance_double(
      TestWorker,
      perform: true,
      rate_limited?: true,
    )
    allow(TestWorker).to receive(:new).and_return(worker_instance)
    allow(Velveteen::TakeToken).to receive(:call)
    message = instance_double(
      Velveteen::Message,
      delivery_info: double(delivery_tag: double),
    )
    allow(TestWorker).to receive(:new).and_return(worker_instance)
    allow(Velveteen::TakeToken).to receive(:call)

    described_class.call(message: message, worker_class: TestWorker)

    expect(Velveteen::TakeToken)
      .to have_received(:call).with(worker: worker_instance)
    expect(worker_instance).to have_received(:perform)
  end
end

RSpec.describe Velveteen::Commands::ParseMessage do
  it "parses the message as JSON and extracts metadata" do
    body = '{"foo": "bar"}'
    delivery_info = double
    metadata = double
    properties = double(headers: metadata)

    message = described_class.call(
      body: body,
      delivery_info: delivery_info,
      properties: properties,
    )

    expect(message.data).to eq(foo: "bar")
    expect(message.metadata).to eq(metadata)
    expect(message.body).to eq(body)
    expect(message.delivery_info).to eq(delivery_info)
    expect(message.properties).to eq(properties)
  end

  it "raises an InvalidMessage error with malformed JSON" do
    expect {
      described_class.call(
        body: "invalid json",
        delivery_info: double,
        properties: double,
      )
    }.to raise_error do |error|
      expect(error).to be_a(Velveteen::InvalidMessage)
      expect(error.cause).to be_a(JSON::ParserError)
    end
  end
end
