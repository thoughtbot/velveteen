module Velveteen
  Message = Struct.new(
    :body,
    :data,
    :delivery_info,
    :headers,
    :properties,
    keyword_init: true
  )
end
