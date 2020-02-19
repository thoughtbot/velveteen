require "velveteen/commands/work"
require "velveteen/worker"

RSpec.describe Velveteen::Commands::HandleMessage do
  class TestWorker < Velveteen::Worker
    def perform
    end
  end

  it "invokes the given worker" do
    exchange = double
    body = "{}"
    worker_instance = instance_double(
      TestWorker,
      perform: true,
      rate_limited?: false,
    )
    allow(TestWorker).to receive(:new).and_return(worker_instance)
    allow(Velveteen::TakeToken).to receive(:call)
    properties = double(headers: {})

    described_class.call(
      body: body,
      exchange: exchange,
      properties: properties,
      worker_class: TestWorker,
    )

    expect(Velveteen::TakeToken)
      .not_to have_received(:call).with(worker: worker_instance)
    expect(worker_instance).to have_received(:perform)
  end

  it "supports rate limiting" do
    exchange = double
    body = "{}"
    worker_instance = instance_double(
      TestWorker,
      perform: true,
      rate_limited?: true,
    )
    allow(TestWorker).to receive(:new).and_return(worker_instance)
    allow(Velveteen::TakeToken).to receive(:call)
    properties = double(headers: {})

    described_class.call(
      body: body,
      exchange: exchange,
      properties: properties,
      worker_class: TestWorker,
    )

    expect(Velveteen::TakeToken)
      .to have_received(:call).with(worker: worker_instance)
    expect(worker_instance).to have_received(:perform)
  end

  it "raises an InvalidMessage error with malformed JSON" do
    expect {
      described_class.call(
        body: "invalid json",
        exchange: double,
        properties: double,
        worker_class: TestWorker,
      )
    }.to raise_error do |error|
      expect(error).to be_a(Velveteen::InvalidMessage)
      expect(error.cause).to be_a(JSON::ParserError)
    end
  end
end
