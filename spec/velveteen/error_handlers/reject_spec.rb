require "velveteen/error_handlers/reject"

RSpec.describe Velveteen::ErrorHandlers::Reject do
  it "rejects the message" do
    delivery_info = double(delivery_tag: "foo")
    message = double(delivery_info: delivery_info)
    worker = double
    error = StandardError.new
    channel = double(reject: true)
    allow(Velveteen::Config).to receive(:channel).and_return(channel)

    described_class.call(
      error: error,
      message: message,
      worker: worker,
      out: StringIO.new,
    )

    expect(Velveteen::Config.channel).to have_received(:reject)
      .with("foo", false)
  end
end
