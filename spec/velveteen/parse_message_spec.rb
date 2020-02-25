require "velveteen/parse_message"
require "velveteen/worker"

RSpec.describe Velveteen::ParseMessage do
  it "parses the message as JSON and extracts headers" do
    body = '{"foo": "bar"}'
    delivery_info = double
    headers = double
    properties = double(headers: headers)

    message = described_class.call(
      body: body,
      delivery_info: delivery_info,
      properties: properties,
    )

    expect(message.data).to eq(foo: "bar")
    expect(message.headers).to eq(headers)
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
