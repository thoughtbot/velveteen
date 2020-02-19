require "velveteen/worker"

RSpec.describe Velveteen::Worker do
  describe ".new" do
    it "raises an error when the incoming message does not match the schema" do
      stub_const("Velveteen::Worker::SCHEMA_DIRECTORY", "spec/schemas")
      message = Velveteen::Message.new(data: {})

      expect {
        TestSchemaWorker.new(message: message)
      }.to raise_error(Velveteen::InvalidMessage, /foo/)
    end
  end

  describe "#publish" do
    it "publishes the message" do
      stub_const("Velveteen::Worker::SCHEMA_DIRECTORY", "spec/schemas")
      message = Velveteen::Message.new(data: {foo: "bar"}, metadata: {})
      worker = TestPublishingWorker.new(message: message)
      queue = Velveteen::Config.channel.queue("")
      queue.bind(
        Velveteen::Config.exchange,
        routing_key: "velveteen.test.publish",
      )

      worker.perform

      _, _, body = queue.pop
      expect(body).to eq('{"foo":"bar"}')
    end

    it "passes along metadata and appends new metadata" do
      stub_const("Velveteen::Worker::SCHEMA_DIRECTORY", "spec/schemas")
      message = Velveteen::Message.new(
        data: {foo: "bar"},
        metadata: {baz: "qux"},
      )
      worker = TestPublishingWorker.new(message: message)
      worker.test_metadata = {name: "fred"}
      queue = Velveteen::Config.channel.queue("")
      queue.bind(
        Velveteen::Config.exchange,
        routing_key: "velveteen.test.publish",
      )

      worker.perform

      _, properties, _ = queue.pop
      expect(properties[:headers]).to eq(baz: "qux", name: "fred")
    end
  end

  class TestSchemaWorker < described_class
    self.message_schema = "test-schema-worker.json"
  end

  class TestPublishingWorker < described_class
    attr_accessor :test_metadata

    def perform
      publish(
        message.data.to_json,
        headers: test_metadata || {},
        routing_key: "velveteen.test.publish",
      )
    end
  end
end
