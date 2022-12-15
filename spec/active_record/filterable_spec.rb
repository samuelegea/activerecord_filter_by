# frozen_string_literal: true

RSpec.describe ActiveRecord::Filterable do # rubocop:disable Metrics/BlockLength
  let(:classes) do
    [
      Post,
      User,
      Like,
      Comment
    ]
  end

  it 'Check if module is included on all classes' do
    classes.each do |klass|
      expect(klass.included_modules).to include(ActiveRecord::Filterable)
    end
  end

  context 'The classes responde to the appropriated methods and return the correct classes' do
    it 'Check if classes respond to filter method' do
      classes.each do |klass|
        expect(klass).to respond_to(:filter)
      end
    end

    it 'Check if classes respond to filter_by_column_name method' do
      classes.each do |klass|
        klass.columns.each do |column|
          expect(klass).to respond_to("filter_by_#{column.name}".to_sym)
        end
      end
    end

    it 'Check if classes respond to filter_by_column_name method and return klass::ActiveRecord_Relation' do
      classes.each do |klass|
        klass.columns.each do |column|
          expect(klass.public_send("filter_by_#{column.name}", 'any string').class)
            .to eq("#{klass}::ActiveRecord_Relation".constantize)
        end
      end
    end
  end

  context 'The queries work as expected with one model' do
  end
end
