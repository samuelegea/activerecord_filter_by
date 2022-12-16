# frozen_string_literal: true

require 'active_support'
require 'active_record'
require_relative 'activerecord_filter_by/version'
require_relative './activerecord_filter_by/active_record_extension'

module ActiverecordFilterBy; end

ActiveSupport.on_load(:active_record) do
  def self.act_as_filterable
    if included_modules.include?(ActiverecordFilterBy)
      puts "[WARN] #{name} is calling act_as_filterable more than once!"

      return
    end
    include ActiverecordFilterBy
  end
end
