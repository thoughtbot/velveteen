require "velveteen/handle_message"

RSpec.describe Velveteen::HandleMessage do
  class TestWorker < Velveteen::Worker
    def perform
    end
  end

  class FailingWorker < Velveteen::Worker
    def perform
      raise "Failed"
    end
  end

  class StuckWorker < Velveteen::Worker
    def perform
      sleep 1
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

  it "handles exceptions in the worker" do
    errors = []
    Velveteen::Config.error_handler = ->(**kwargs) {
      errors << kwargs
    }
    message = instance_double(
      Velveteen::Message,
      delivery_info: double(delivery_tag: double)
    )

    described_class.call(message: message, worker_class: FailingWorker)

    expect(errors.size).to eq 1
    error = errors.first
    expect(error[:error]).to be_a RuntimeError
    expect(error[:message]).to eq message
    expect(error[:worker_class]).to eq FailingWorker
  end

  it "times out workers" do
    errors = []
    Velveteen::Config.error_handler = ->(**kwargs) {
      errors << kwargs
    }
    Velveteen::Config.worker_timeout = 0.1
    message = instance_double(
      Velveteen::Message,
      delivery_info: double(delivery_tag: double)
    )

    described_class.call(message: message, worker_class: StuckWorker)

    expect(errors.size).to eq 1
    error = errors.first
    expect(error[:error]).to be_a Velveteen::WorkerTimeout
    expect(error[:error].message).to eq "timed out after 0.1s"
    expect(error[:message]).to eq message
    expect(error[:worker_class]).to eq StuckWorker
  end
end
