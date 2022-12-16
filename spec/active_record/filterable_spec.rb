# frozen_string_literal: true

RSpec.describe ActiveRecord::Filterable do
  let(:classes) do
    [
      Post,
      User,
      Like,
      Comment
    ]
  end

  let(:one_day_ago) { 1.day.ago }

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

  context 'The auto generated methods queries work as expected' do
    it 'Check if filter_by_not_column_name methods works' do
      classes.each do |klass|
        klass.columns.each do |column|
          expect(klass.public_send("filter_by_#{column.name}", 'any string').to_sql)
            .to eq(klass.where(column.name => 'any string').to_sql)
        end
      end
    end

    it 'Check if filter_by_not_column_name methods works' do
      classes.each do |klass|
        klass.columns.each do |column|
          expect(klass.public_send("filter_by_not_#{column.name}", 'any string').to_sql)
            .to eq(klass.where.not(column.name => 'any string').to_sql)
        end
      end
    end
  end

  context 'The filter method works as expected' do
    it 'Check if filter with one named argument results in a simple query' do
      expect(User.filter(name: 'Jhon').to_sql).to eq(User.where(name: 'Jhon').to_sql)
    end

    it 'Check if filter with two named argument results in a and query' do
      expect(User.filter(name: 'Jhon', email: 'email@email.com').to_sql).to eq(User.where(name: 'Jhon', email: 'email@email.com').to_sql)
    end

    it 'Check if filter with two named argument inside hashed results in a or query' do
      expect(User.filter({ name: 'Jhon' }, { email: 'email@email.com' }).to_sql).to eq(User.where(name: 'Jhon').or(User.where(email: 'email@email.com')).to_sql)
    end

    it 'Check if filter with two named argument, inside array results in a or query' do
      expect(User.filter([{ name: 'Jhon' }, { email: 'email@email.com' }]).to_sql).to eq(User.where(name: 'Jhon').or(User.where(email: 'email@email.com')).to_sql)
    end

    it 'Check if filter with a argument named or: results in a or query' do
      expect(User.filter(or: [{ name: 'Jhon' }, { email: 'email@email.com' }]).to_sql).to eq(User.where(name: 'Jhon').or(User.where(email: 'email@email.com')).to_sql)
    end

    it 'Check if filter with a argument named or:, alongside with other named arguments results in a complex query' do
      expect(User.filter(name: 'Jhon', or: [{ name: 'Smith' }, { email: 'email@email.com' }]).to_sql).to eq(User.where(name: 'Jhon').merge(User.where(name: 'Smith').or(User.where(email: 'email@email.com'))).to_sql)
    end
  end

  context 'The define_filter method works as expected' do
    subject { User.define_filter :posts_that_have_more_than_n_comments, ->(number_of_comments) { joins(posts: :comments).group('posts.id').having('count(comments.id) > ?', number_of_comments) } }
    it 'Check if define_filter actually defines the filter prepending the name with filter_by_ and creates a class method with that name' do
      subject
      expect(User).to respond_to('filter_by_posts_that_have_more_than_n_comments'.to_sym)
    end

    it 'Check if defined filter actually executes the correct query' do
      subject
      expect(User.filter_by_posts_that_have_more_than_n_comments(30).to_sql).to eq(User.joins(posts: :comments).group('posts.id').having('count(comments.id) > ?', 30).to_sql)
    end

    it 'Check if defined_filter can be accessed by the filter method' do
      subject
      expect(User.filter(posts_that_have_more_than_n_comments: 30).to_sql).to eq(User.joins(posts: :comments).group('posts.id').having('count(comments.id) > ?', 30).to_sql)
    end

    it 'Check if defined_filter can be accessed by the filter method with other named arguments' do
      subject
      expect(User.filter(name: 'Jhon', posts_that_have_more_than_n_comments: 30).to_sql).to eq(User.where(name: 'Jhon').merge(User.joins(posts: :comments).group('posts.id').having('count(comments.id) > ?', 30)).to_sql)
    end
  end

  context 'The define_filter method works as expected defining a block after it' do
    subject do
      User.define_filter :posts_that_have_more_than_n_comments, ->(number_of_comments) { joins(posts: :comments).group('posts.id').having('count(comments.id) > ?', number_of_comments) } do
        def older_than(datetime)
          where('posts.created_at < ?', datetime)
        end

        def newer_than(datetime)
          where('posts.created_at > ?', datetime)
        end
      end
    end

    it 'Check if defined filter actually executes the correct query' do
      subject
      expect(User.filter_by_posts_that_have_more_than_n_comments(30).to_sql).to eq(User.joins(posts: :comments).group('posts.id').having('count(comments.id) > ?', 30).to_sql)
    end

    it 'Check if defined filter can be accessed by the filter method' do
      subject
      expect(User.filter(posts_that_have_more_than_n_comments: 30).to_sql).to eq(User.joins(posts: :comments).group('posts.id').having('count(comments.id) > ?', 30).to_sql)
    end

    it 'Check if defined filter can respond to methods defined inside its block and it executes the right query' do
      subject
      expect(User.filter_by_posts_that_have_more_than_n_comments(30).older_than(one_day_ago).to_sql).to eq(User.joins(posts: :comments).group('posts.id').having('count(comments.id) > ?', 30).where('posts.created_at < ?', one_day_ago).to_sql)
      expect(User.filter_by_posts_that_have_more_than_n_comments(30).newer_than(one_day_ago).to_sql).to eq(User.joins(posts: :comments).group('posts.id').having('count(comments.id) > ?', 30).where('posts.created_at > ?', one_day_ago).to_sql)
    end
  end
end
