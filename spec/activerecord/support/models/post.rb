class Post < ActiveRecord::Base
  belongs_to :author, class_name: 'User', foreign_key: 'author_id'
  has_many :likes, as: :likable
  has_many :comments
end
