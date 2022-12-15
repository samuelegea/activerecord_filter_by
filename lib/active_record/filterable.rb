# frozen_string_literal: true

require 'active_support'
require 'active_record'
require_relative 'filterable/version'
require_relative './filterable/active_record_extension'

module ActiveRecord
  module Filterable
  end

  ActiveSupport.on_load(:active_record) do
    def self.act_as_filterable
      if included_modules.include?(Filterable)
        puts "[WARN] #{name} is calling act_as_filterable more than once!"

        return
      end
      include Filterable
    end
  end
end
