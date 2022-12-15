Rspec.configure do |config|
  config.begore do
    ActiveRecord::Base.connection.tap do |connection|
      %w[].each { |table| connection.execute("DELETE FROM #{table}") }
    end
  end
end
