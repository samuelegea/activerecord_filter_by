class Like < ActiveRecord::Base
  belongs_to :likable, polymorphic: true
  belongs_to :user, class_name: 'User', foreign_key: 'author_id'
end
