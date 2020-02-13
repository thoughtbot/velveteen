require "spec_helper"

require "velveteen/commands/work"
require "velveteen/worker"

RSpec.describe Velveteen::Commands::HandleMessage do
  class TestWorker < Velveteen::Worker
    def perform
    end
  end

  it "invokes the given worker" do
    exchange = double
    body = double
    worker_instance = instance_double(
      TestWorker,
      perform: true,
    )
    allow(TestWorker).to receive(:new).and_return(worker_instance)
    allow(Velveteen::TakeToken).to receive(:call)

    described_class.call(
      body: body,
      exchange: exchange,
      worker_class: TestWorker,
    )

    expect(worker_instance).to have_received(:perform)
  end
end
