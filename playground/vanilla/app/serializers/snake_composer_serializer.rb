class SnakeComposerSerializer < ComposerSerializer
  transform_keys ->(key) { key }
end
