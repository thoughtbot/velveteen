require "json-schema"

module Velveteen
  class Worker
    SCHEMA_DIRECTORY = "app/message_schemas"

    attr_reader :exchange, :message

    class << self
      attr_accessor(
        :exchange_name,
        :message_schema,
        :queue_name,
        :rate_limit_key,
        :routing_key,
      )
    end

    def initialize(exchange:, message:)
      @exchange = exchange
      @message = message

      maybe_validate_message!
    end

    def rate_limited?
      !!self.class.rate_limit_key
    end

    def exchange_name
      self.class.exchange_name
    end

    def rate_limit_key
      self.class.rate_limit_key
    end

    private

    def publish(payload, options = {})
      options[:headers] = message.metadata.merge(options.fetch(:headers, {}))
      exchange.publish(payload, options)
    end

    def message_schema
      if self.class.message_schema
        File.expand_path(self.class.message_schema, SCHEMA_DIRECTORY)
      end
    end

    def maybe_validate_message!
      if message_schema
        errors = JSON::Validator.fully_validate(message_schema, message.data)

        if errors.any?
          raise InvalidMessage, errors.join("\n")
        end
      end
    end
  end
end
