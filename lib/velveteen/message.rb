module Velveteen
  Message = Struct.new(
    :body,
    :data,
    :delivery_info,
    :properties,
    keyword_init: true,
  ) {
    def headers
      properties.headers
    end

    def metadata
      headers.fetch(:metadata, {})
    end
  }
end
