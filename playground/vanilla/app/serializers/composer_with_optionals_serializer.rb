class ComposerWithOptionalsSerializer < BaseSerializer
  attributes(
    id: {optional: false},
    last_name: {optional: true},
    first_name: {optional: :null},
    name: {type: :string, optional: :undefined_or_null},
  )
end
