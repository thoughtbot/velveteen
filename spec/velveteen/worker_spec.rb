require "velveteen/worker"

RSpec.describe Velveteen::Worker do
  describe ".new" do
    it "raises an error when the incoming message does not match the schema" do
      message = Velveteen::Message.new(data: {})

      expect {
        TestSchemaWorker.new(message: message)
      }.to raise_error(Velveteen::InvalidMessage, /foo/)
    end
  end

  describe "#publish" do
    it "publishes the message" do
      message = Velveteen::Message.new(data: {foo: "bar"}, headers: {})
      worker = TestPublishingWorker.new(message: message)
      queue = Velveteen::Config.channel.queue("")
      queue.bind(
        Velveteen::Config.exchange,
        routing_key: "velveteen.test.publish"
      )

      worker.perform

      _, _, body = queue.pop
      expect(body).to eq('{"foo":"bar"}')
    end

    it "passes along headers and appends new headers" do
      message = Velveteen::Message.new(
        data: {foo: "bar"},
        headers: {baz: "qux"}
      )
      worker = TestPublishingWorker.new(message: message)
      worker.test_headers = {name: "fred"}
      queue = Velveteen::Config.channel.queue("")
      queue.bind(
        Velveteen::Config.exchange,
        routing_key: "velveteen.test.publish"
      )

      worker.perform

      _, properties, _ = queue.pop
      expect(properties[:headers]).to eq(baz: "qux", name: "fred")
    end

    it "does not pass along reserved RabbitMQ headers" do
      message = Velveteen::Message.new(
        data: {foo: "bar"},
        headers: {"x-death": [{count: 1}]}
      )
      worker = TestPublishingWorker.new(message: message)
      worker.test_headers = {foo: "bar"}
      queue = Velveteen::Config.channel.queue("")
      queue.bind(
        Velveteen::Config.exchange,
        routing_key: "velveteen.test.publish"
      )

      worker.perform

      _, properties, _ = queue.pop
      expect(properties[:headers]).to eq(foo: "bar")
    end
  end

  class TestSchemaWorker < described_class
    self.message_schema = "test-schema-worker.json"
  end

  class TestPublishingWorker < described_class
    attr_accessor :test_headers

    def perform
      publish(
        message.data.to_json,
        headers: test_headers || {},
        routing_key: "velveteen.test.publish"
      )
    end
  end
end
