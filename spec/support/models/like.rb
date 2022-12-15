# frozen_string_literal: true

class Like < ActiveRecord::Base
  act_as_filterable

  belongs_to :likable, polymorphic: true
  belongs_to :user, class_name: 'User', foreign_key: 'author_id'
end
