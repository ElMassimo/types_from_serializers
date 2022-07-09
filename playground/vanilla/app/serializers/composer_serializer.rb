class ComposerSerializer < BaseSerializer
  attributes(
    :id,
    :first_name,
    :last_name,
  )

  typed_attributes(
    name: :string,
  )
end
