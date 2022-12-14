require 'active_record'

ActiveRecord::Base.establish_connection(adapter: 'sqlite3', database: ':memory:')

ActiveRecord::Base.connection.create_table :users do |t|
  t.string :name
  t.string :email
  t.string :password_digest
  t.datetime :created_at
  t.datetime :updated_at
end

ActiveRecord::Base.connection.create_table :posts do |t|
  t.string :title
  t.text :body
  t.bigint :author_id, foreign_key: { to_table: :users }
  t.datetime :created_at
  t.datetime :updated_at
end

ActiveRecord::Base.connection.create_table :comments do |t|
  t.bigint :author_id, foreign_key: { to_table: :users }
  t.text :body
  t.references :posts
  t.datetime :created_at
  t.datetime :updated_at
end

ActiveRecord::Base.connection.create_table :likes do |t|
  t.bigint :user_id, foreign_key: true
  t.bigint :likable_id
  t.string :likable_type
  t.datetime :created_at
  t.datetime :updated_at
end

require_relative './models/user'
require_relative './models/post'
require_relative './models/comment'
require_relative './models/like'
