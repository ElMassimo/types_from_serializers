class CommentSerializer < BaseSerializer
  object_as :comment, model: :Comment

  attributes :id, :content, :author_name, :created_at

  has_many :replies, serializer: CommentSerializer
end
