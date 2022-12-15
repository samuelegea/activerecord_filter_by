# frozen_string_literal: true

class Comment < ActiveRecord::Base
  act_as_filterable

  has_many :likes, as: :likable
  belongs_to :post
  belongs_to :user, class_name: 'User', foreign_key: 'author_id'
end
