class Ams::ComposerSerializer < Ams::BaseSerializer
  object_as :composer

  attributes :id, :first_name, :last_name
end
