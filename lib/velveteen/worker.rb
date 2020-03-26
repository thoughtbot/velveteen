require "json-schema"

module Velveteen
  class Worker
    IGNORED_HEADERS = ["x-death"].freeze

    attr_reader :message

    class << self
      attr_accessor :message_schema, :rate_limit_queue, :routing_key
    end

    def initialize(message:)
      @message = message

      maybe_validate_message!
    end

    def self.queue_name
      name
    end

    def rate_limited?
      !!self.class.rate_limit_queue
    end

    def rate_limit_queue
      self.class.rate_limit_queue
    end

    def queue_name
      self.class.queue_name
    end

    def routing_key
      self.class.routing_key
    end

    private

    def logger
      Velveteen.logger
    end

    def publish(payload, options = {})
      validate_payload!(payload, options[:routing_key])
      options[:headers] = build_headers(options)
      Config.exchange.publish(payload, options)
    end

    def validate_payload!(payload, routing_key)
      errors = JSON::Validator.fully_validate(
        generate_schema(routing_key),
        payload
      )

      if errors.any?
        raise InvalidMessage, errors.join("\n")
      end
    end

    def generate_schema(routing_key)
      schema_file_path = routing_key + ".json"
      File.expand_path(schema_file_path, Config.schema_directory)
    end

    def message_schema
      if self.class.message_schema
        File.expand_path(self.class.message_schema, Config.schema_directory)
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

    def build_headers(options)
      forwardable_headers.merge(options.fetch(:headers, {}))
    end

    def forwardable_headers
      message.headers.reject { |key, _| IGNORED_HEADERS.include?(key.to_s) }
    end
  end
end
