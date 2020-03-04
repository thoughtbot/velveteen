module Velveteen
  class ParseMessage
    def self.call(body:, delivery_info:, properties:)
      data = JSON.parse(body, symbolize_names: true)

      Message.new(
        body: body,
        data: data,
        delivery_info: delivery_info,
        headers: properties.headers,
        properties: properties
      )
    rescue JSON::ParserError => e
      raise InvalidMessage.new(e)
    end
  end
end
