require "velveteen/worker"

RSpec.describe Velveteen::Worker do
  describe ".new" do
    it "raises an error when the incoming message does not match the schema" do
      stub_const("Velveteen::Worker::SCHEMA_DIRECTORY", "spec/schemas")
      message = Velveteen::Message.new(data: {})
      exchange = double

      expect {
        TestSchemaWorker.new(exchange: exchange, message: message)
      }.to raise_error(Velveteen::InvalidMessage, /foo/)
    end
  end

  describe "#publish" do
    it "publishes the message to the exchange" do
      stub_const("Velveteen::Worker::SCHEMA_DIRECTORY", "spec/schemas")
      message = Velveteen::Message.new(data: {foo: "bar"})
      exchange = double(publish: true)
      worker = TestPublishingWorker.new(exchange: exchange, message: message)

      worker.perform

      expect(exchange).to have_received(:publish)
        .with('{"foo":"bar"}', routing_key: "velveteen.test.publish")
    end
  end

  class TestSchemaWorker < described_class
    self.message_schema = "test-schema-worker.json"
  end

  class TestPublishingWorker < described_class
    def perform
      publish(message.data.to_json, routing_key: "velveteen.test.publish")
    end
  end
end
