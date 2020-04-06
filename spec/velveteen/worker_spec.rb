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
      message = Velveteen::Message.new(data: {"foo" => "bar"}, headers: {})
      worker = TestPublishingWorker.new(message: message)
      queue = Velveteen::Config.channel.queue
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
        data: {"foo" => "bar"},
        headers: {"baz" => "qux"}
      )
      worker = TestPublishingWorker.new(message: message)
      worker.test_headers = {"name" => "fred"}
      queue = Velveteen::Config.channel.queue
      queue.bind(
        Velveteen::Config.exchange,
        routing_key: "velveteen.test.publish"
      )

      worker.perform

      _, properties, _ = queue.pop
      expect(properties[:headers]).to eq("baz" => "qux", "name" => "fred")
    end

    it "does not pass along reserved RabbitMQ headers" do
      message = Velveteen::Message.new(
        data: {"foo" => "bar"},
        headers: {"x-death" => [{"count" => 1}]}
      )
      worker = TestPublishingWorker.new(message: message)
      worker.test_headers = {"foo" => "bar"}
      queue = Velveteen::Config.channel.queue
      queue.bind(
        Velveteen::Config.exchange,
        routing_key: "velveteen.test.publish"
      )

      worker.perform

      _, properties, _ = queue.pop
      expect(properties[:headers]).to eq("foo" => "bar")
    end

    describe "payload validation" do
      it "raises an error when payload does not match schema" do
        message = Velveteen::Message.new(
          data: {"foo" => "bar"},
          headers: {}
        )
        invalid_payload = {
          data: {"coffee" => "espresso"},
          headers: {}
        }
        worker = TestValidatesPayloadWorker.new(
          message: message,
          payload: invalid_payload
        )

        expect {
          worker.perform
        }.to raise_error(Velveteen::InvalidMessage, /tea/)
      end

      it "publishes when payload matches routing key schema" do
        message = Velveteen::Message.new(
          data: {"foo" => "bar"},
          headers: {}
        )
        payload = {
          data: {"tea" => "boba"},
          headers: {}
        }
        worker = TestValidatesPayloadWorker.new(
          message: message,
          payload: payload
        )
        queue = Velveteen::Config.channel.queue
        queue.bind(
          Velveteen::Config.exchange,
          routing_key: "worker.test.tea.ordered"
        )

        worker.perform

        _, _, body = queue.pop
        expect(body).to eq('{"tea":"boba"}')
      end
    end
  end

  class TestSchemaWorker < described_class
    self.routing_key = "velveteen.test.publish"
  end

  class TestPublishingWorker < described_class
    attr_accessor :test_headers
    self.routing_key = "velveteen.test.publish"

    def perform
      publish(
        message.data.to_json,
        headers: test_headers || {},
        routing_key: "velveteen.test.publish"
      )
    end
  end

  class TestValidatesPayloadWorker < described_class
    attr_reader :payload
    self.routing_key = "velveteen.test.publish"

    def initialize(message:, payload: nil)
      super(message: message)
      @payload = payload
    end

    def perform
      publish(
        payload[:data].to_json,
        headers: payload[:headers],
        routing_key: "worker.test.tea.ordered"
      )
    end
  end
end
