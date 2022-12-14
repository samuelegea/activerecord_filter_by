class Comment < ActiveRecord::Base
  has_many :likes, as: :likable
  belongs_to :post
  belongs_to :user, class_name: 'User', foreign_key: 'author_id'
end
