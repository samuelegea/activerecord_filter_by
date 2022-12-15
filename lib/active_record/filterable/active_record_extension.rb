module ActiveRecord::Filterable
  def self.included(base)
    base.extend(ClassMethods)

    base.singleton_class.class_eval do
      base.columns.each do |column|

        # Redefined method for each column, since the ActiveRecord::DynamicMatchers methods such as #filter_by_column_name aren't chainable
        # You can redefine this method to add more functionality, but you must return ActiveRecord::Relation

        define_method("filter_by_#{column.name}") do |filter|
          where(column.name.to_sym => filter)
        end

        # Testing the not operator
        # define_method("filter_by_not_#{column.name}") do |filter|
        #   where.not(column.name.to_sym => filter)
        # end
      end
    end
  end

  module ClassMethods
    # This adds the ability to filter by a hash or an array of hashes, the hash keys are the column names and the values are the values to filter
    # Example:
    # User.filter({name: "Jhon"}).to_sql
    # => "SELECT \"users\".* FROM \"users\" WHERE \"users\".\"name\" = 'Jhon'"

    # User.filter([{name: "Jhon"}, {name: "doe"}]).to_sql
    # => "SELECT \"users\".* FROM \"users\" WHERE ( \"users\".\"name\" = 'Jhon' AND \"users\".\"name\" = 'doe' )"

    # Also you can use the or operator to filter by multiple values
    # User.filter([{name: "Jhon", email: "joaquin", or: [{name: "smith"}, {email: "smit"}]}, {name: "doe"}]).to_sql
    # => "SELECT \"users\".* FROM \"users\" WHERE ( \"users\".\"name\" = 'Jhon' AND \"users\".\"email\" = 'joaquin' AND ( \"users\".\"name\" = 'smith' OR \"users\".\"email\" = 'smit' ) AND \"users\".\"name\" = 'doe' )"
    def filter(*params)
      raise ArgumentError, message: 'params must be a Hash or a Array' unless [Array, Hash].include? params.class
      
      params.flatten!
      pp "Params: #{params}, params class: #{params.class}"

      return and_filter(params: params) if params.is_a?(Hash)
      return or_filter(params: params) if params.is_a?(Array)
    end

    def and_filter(params:)
      query = self

      params.map do |key, value|
        query = if key.to_s.include? 'or'
                  query.merge(or_filter(params: value))
                else
                  query.merge send("filter_by_#{key}", value)
                end
      end
      query
    end

    def or_filter(params:)
      raise ArgumentError, message: 'Params should be a array' unless params.is_a? Array

      query = and_filter params: params.first
      params.drop(1)

      params.map do |param|
        query = query.or and_filter(params: param)
      end
      query
    end
  end
end
