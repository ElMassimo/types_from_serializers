class ComposerSerializer < BaseSerializer
  attributes(
    :id,
    :last_name,
    :first_name,
    name: {type: :string},
  )
end
