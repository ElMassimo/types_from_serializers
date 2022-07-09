class ModelSerializer < BaseSerializer
  typed_attributes(
    id: :number,
    title: :string,
  )
end
