class BaseSerializer < Oj::Serializer
  include TypesFromSerializers::DSL

  transform_keys :camelize
end
