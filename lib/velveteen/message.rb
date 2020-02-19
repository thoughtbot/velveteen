module Velveteen
  Message = Struct.new(
    :body,
    :data,
    :delivery_info,
    :metadata,
    :properties,
    keyword_init: true,
  )
end
