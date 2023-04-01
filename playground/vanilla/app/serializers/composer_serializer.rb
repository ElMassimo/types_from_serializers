class ComposerSerializer < BaseSerializer
  attributes(
    :id,
    :first_name,
    :last_name,
    name: {type: :string},
  )
end
