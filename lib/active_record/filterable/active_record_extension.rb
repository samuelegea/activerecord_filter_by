# frozen_string_literal: true

module ActiveRecord
  module Filterable
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
          # This defines the not operator, so you can filter by a column that is not equal to a value
          # Example:
          # User.filter_by_not_name("Jhon").to_sql
          # => "SELECT \"users\".* FROM \"users\" WHERE \"users\".\"name\" != 'Jhon'"
          # User.filter_by_not_deleted_at(nil).to_sql
          # => "SELECT \"users\".* FROM \"users\" WHERE \"users\".\"deleted_at\" IS NOT NULL"

          define_method("filter_by_not_#{column.name}") do |filter|
            where.not(column.name.to_sym => filter)
          end

          # Define a define_filter helper, to define the class methods in a more readable way,
          # You can always define a class method started with "filter_by_", or use the scope method, from Rails
          # And even use the filter method equally to the scope method, with lambda or proc, the same rules apply
          # Either way, you must return an ActiveRecord::Relation at the end of the method

          # Example:
          # define_filter :name_of_child, ->(name) { joins(:childs).where(child: { name: name }) }
          # will generate a class method like User#filter_by_name
          # that will perform the query: User.joins(:childs).where(child: { name: name })
          # You can also define a block, that will be extended to the scope, so you can define more methods
          # Example:
          # define_filter :name_of_child, ->(name) { joins(:childs).where(child: { name: name }) } do
          #   def with_age(age)
          #     where(child: { age: age })
          #   end
          # end
          # will generate a class method like User#filter_by_name_of_child
          # Using like User.filter_by_name_of_child("Jhon").with_age(10)
          # that will return a query like:
          # => "SELECT \"users\".* FROM \"users\" INNER JOIN \"childs\" ON \"childs\".\"user_id\" = \"users\".\"id\" WHERE \"childs\".\"name\" = 'Jhon' AND \"childs\".\"age\" = 10"
          # Any method defined in the block will be available in the scope
          # Althought it would not be very advisable because the #filter won't catch these block methods,
          # it can be useful elsewhere, so you can use it as you wish.

          def define_filter(name, body, &block)
            raise ArgumentError, 'The scope body needs to be callable.' unless body.respond_to?(:call)

            if dangerous_class_method?("filter_by_#{name}")
              raise ArgumentError, "You tried to define a filter named \"#{name}\" " \
                "on the model \"#{self.name}\", but Active Record already defined " \
                'a class method with the same name.'
            end

            extension = Module.new(&block) if block

            if body.respond_to?(:to_proc)
              singleton_class.define_method("filter_by_#{name}") do |*args|
                scope = all._exec_scope(*args, &body)
                scope = scope.extending(extension) if extension
                scope
              end
            else
              singleton_class.define_method("filter_by_#{name}") do |*args|
                scope = body.call(*args) || all
                scope = scope.extending(extension) if extension
                scope
              end
            end
          end
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
end
