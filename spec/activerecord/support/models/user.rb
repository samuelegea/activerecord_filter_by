# class User < ActiveRecord::Base
#   has_many :posts, class_name: 'Post', foreign_key: 'author_id'
#   has_many :likes, class_name: 'Like', foreign_key: 'author_id'
#   has_many :comments, class_name: 'Comment', foreign_key: 'author_id'

# end
class User < ActiveRecord::Base
  include ActiveRecord::Filterable
end

# User.filter({name: "Jhon"})
# User.filter([{name: "Jhon"}, {name: "doe"}]).to_sql
User.filter([{name: "Jhon", email: "joaquin", or: [{name: "smith"}, {email: "smit"}]}, {name: "doe"}]).to_sql
