# ActiveRecord::Filterable

This is a gem created with the intent of being a go-to sollution when it comes to filtering your records with active record.
The way we try to do it is creatin a `filter` method, where you can execute complex queries over your models, or simple ones as well, always maintaining the logic that you pass down.
The gem also allows you to configure your own custom filters, with all the complex logic that you want, following a pattern developed by the [rails](https://github.com/rails/rails) guys, used on the `scope` method.

## Installation

Install the gem and add to the application's Gemfile by executing:

    $ bundle add active_record-filterable

If bundler is not being used to manage dependencies, install the gem by executing:

    $ gem install active_record-filterable

Or just add it to your Gemfile

```
gem 'active_record-filterable
```

## Usage

### The models

For the models that you want to respond to the `filter` method, you should add a `act_as_filterable` to it, like this:

```ruby
class User < ActiveRecord::Base
  act_as_filterable
end
```

When you do it, the gem will redefine the `ActiveRecord::DynamicMatchers` for your columns, because the rails sollution, unfortunally doesn't retur a `Class::ActiveRecord_Relation`, so it can't be queried further.

```ruby
# This model
User(id: integer, name: string, email: string, password_digest: string, created_at: datetime, updated_at: datetime)

# will have:

User#filter_by_id
User#filter_by_name
User#filter_by_email
User#filter_by_password_digest
User#filter_by_created_at
User#filter_by_updated_at
```

Note: The `filter_by_` prepend it's very important for this gem, as we are going to see further

### Using the filter method

This gem introduces the filter method for all models that have the `act_as_filterable` in it, and to use it, you could just:

```ruby
User.filter(name: 'Jhon')
# will produce the following query
# => "SELECT \"users\".* FROM \"users\" WHERE \"users\".\"name\" = 'Jhon'"
```

And you can query like normal, continuing to give named params to it, and it will be continuing the query with the **AND** operator, like so:

```ruby
User.filter(name: 'Jhon', email: 'jhon.smith@email.com')
# will produce the following query
# => "SELECT \"users\".* FROM \"users\" WHERE \"users\".\"name\" = 'Jhon'" AND \"users\".\"email\" = 'jhon.smith@email.com'"
```

So far, nothing spicy, right? Pretty much like the `where` method, default on the models.
But now, you can query with **OR** conditions, just making sure that you are passing down an Array instead of a Hash.

```ruby
User.filter([{name: "Jhon"}, {name: "doe"}])
# will produce
#   => "SELECT \"users\".* FROM \"users\" WHERE ( \"users\".\"name\" = 'Jhon' AND \"users\".\"name\" = 'doe' )"
```

And going down even further, if you need to have a complex case with and **OR** condition nested within the **AND** condition, just use a `:or` key, passing an array to it, like so:

```ruby
User.filter([{name: "Jhon", email: "joaquin", or: [{name: "smith"}, {email: "smit"}]}, {name: "doe"}])
# will produce the following query
#   => "SELECT \"users\".* FROM \"users\" WHERE ( \"users\".\"name\" = 'Jhon' AND \"users\".\"email\" = 'joaquin' AND ( \"users\".\"name\" = 'smith' OR \"users\".\"email\" = 'smit' ) AND \"users\".\"name\" = 'doe' )"
```

The rule of thumb is:

- If it is an **Array** -> the elements are joined by **OR** conditions
- If it is an **Hash** -> the elements are joined by **AND** conditions

You can go as nested as you want, until you reach the call stack limit.

### Define your own filters

Every **class method** prepended with `filter_by` will turn into a valid key for the filter method, but we put down some helper methods to help you define it, using the `scope` pattern, already present in `ActiveRecord`

For instance if you have a custom, joined query to perform and you want for it to be in your possible keys for the filter method, you define it as the following:

```ruby
class User < ActiveRecord::Base
  act_as_filterable
  has_many :posts, class_name: 'Post', foreign_key: 'author_id'
  has_many :likes, class_name: 'Like', foreign_key: 'author_id'
  has_many :comments, class_name: 'Comment', foreign_key: 'author_id'

  define_filter :posts_that_have_more_than_n_comments, ->(number_of_comments) { joins(posts: :comments).group('posts.id').having('count(comments.id) > ?', number_of_comments) }
end

```

The `define_filter` method takes up to 3 arguments, only requiring the first 2:

- The name of the filter
  - Will be the name of the class method generated, prepened by "filter_by\_"
- The proc to be performed
  - Will be the body of said method
- A block that extend its functionality
  - Can also be the body, if you rather declare it this way, or other methods that extend the filter functionality, more on that later.

Note: You can define you own class methods, if you want, or use the already well tested `scope` API, rather than that from the gem, it's really up to you.

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/activerecord-filterable.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
