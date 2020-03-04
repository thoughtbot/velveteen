require "velveteen/handle_message"

RSpec.describe Velveteen::HandleMessage do
  class TestWorker < Velveteen::Worker
    def perform
    end
  end

  it "invokes the given worker" do
    worker_instance = instance_double(
      TestWorker,
      perform: true,
      rate_limited?: false
    )
    allow(TestWorker).to receive(:new).and_return(worker_instance)
    allow(Velveteen::TakeToken).to receive(:call)
    message = instance_double(
      Velveteen::Message,
      delivery_info: double(delivery_tag: double)
    )

    described_class.call(
      message: message,
      worker_class: TestWorker
    )

    expect(Velveteen::TakeToken)
      .not_to have_received(:call).with(worker: worker_instance)
    expect(worker_instance).to have_received(:perform)
  end

  it "supports rate limiting" do
    worker_instance = instance_double(
      TestWorker,
      perform: true,
      rate_limited?: true
    )
    allow(TestWorker).to receive(:new).and_return(worker_instance)
    allow(Velveteen::TakeToken).to receive(:call)
    message = instance_double(
      Velveteen::Message,
      delivery_info: double(delivery_tag: double)
    )
    allow(TestWorker).to receive(:new).and_return(worker_instance)
    allow(Velveteen::TakeToken).to receive(:call)

    described_class.call(message: message, worker_class: TestWorker)

    expect(Velveteen::TakeToken)
      .to have_received(:call).with(worker: worker_instance)
    expect(worker_instance).to have_received(:perform)
  end
end
