# frozen_string_literal: true

require 'active_support'
require 'active_record'
require_relative 'activerecord_filterable/version'
require_relative './activerecord_filterable/active_record_extension'

module ActiverecordFilterable; end

ActiveSupport.on_load(:active_record) do
  def self.act_as_filterable
    if included_modules.include?(ActiverecordFilterable)
      puts "[WARN] #{name} is calling act_as_filterable more than once!"

      return
    end
    include ActiverecordFilterable
  end
end
