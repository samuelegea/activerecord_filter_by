# frozen_string_literal: true

class User < ActiveRecord::Base
  act_as_filterable
  has_many :posts, class_name: 'Post', foreign_key: 'author_id'
  has_many :likes, class_name: 'Like', foreign_key: 'author_id'
  has_many :comments, class_name: 'Comment', foreign_key: 'author_id'

  define_filter :posts_that_have_more_than_n_likes, ->(number_of_likes) { joins(posts: :likes).group('posts.id').having('count(likes.id) > ?', number_of_likes) } do
    def newer_than(date)
      where('posts.created_at > ?', date)
    end

    def older_than(date)
      where('posts.created_at < ?', date)
    end
  end

  define_filter :posts_that_have_more_than_n_comments, ->(number_of_comments) { joins(posts: :comments).group('posts.id').having('count(comments.id) > ?', number_of_comments) }
end
