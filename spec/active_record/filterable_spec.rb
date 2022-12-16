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
  let(:user)        { User.create(name: 'John Doe', email: 'email@email.com', password_digest: '123456') }
  let(:second_user) { User.create(name: 'John Smith', email: 'email2@email.com', password_digest: '123') }
  let(:post)        { Post.create(title: 'Title', body: 'Body', author_id: user.id) }
  let(:second_post) { Post.create(title: 'Title', body: 'Body', author_id: second_user.id) }
  let(:comment)     { Comment.create(body: 'Body', author_id: user.id, post_id: post.id) }

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
end
