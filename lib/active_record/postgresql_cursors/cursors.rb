
module ActiveRecord
  module CursorExtensions
    extend ActiveSupport::Concern

    included do
      alias_method_chain :find, :cursors
    end

    # Override ActiveRecord::Base#find to allow for cursors in
    # PostgreSQL. To use a cursor, set the first argument of
    # find to :cursor. A PostgreSQLCursor object will be returned,
    # which can then be used as an Enumerable to loop through the
    # results.
    #
    # By default, cursor names are generated automatically using
    # "cursor_#{rand}", where rand is a big ol' random number that
    # is pretty unlikely to clash if you're using nested cursors.
    # Alternatively, you can supply a specific cursor name by
    # supplying a :cursor_name option.
    def find_with_cursors(*args)
      if args.first.to_s == 'cursor'
        options = args.extract_options!
        cursor_name = options.delete(:cursor_name)
        find_cursor(cursor_name, options)
      else
        find_without_cursors(*args)
      end
    end

    def cursor(*args)
      find_with_cursors('cursor', *args)
    end

    private
      # Find method for using cursors. This works just like the regular
      # ActiveRecord::Base#find_every method, except it returns a
      # PostgreSQLCursor object that can be used to loop through records.
      def find_cursor(cursor_name, options)
        unless connection.is_a? ActiveRecord::ConnectionAdapters::PostgreSQLAdapter
          raise CursorsNotSupported, "#{connection.class} doesn't support cursors"
        end

        relation = apply_finder_options(options, silence_deprecation = true)
        including = (relation.eager_load_values + relation.includes_values).uniq

        if including.present?
          join_dependency = ActiveRecord::Associations::JoinDependency.new(@klass, including, [])
          join_relation = relation.construct_relation_for_association_find(join_dependency)

          ActiveRecord::PostgreSQLCursor.new(self, cursor_name, join_relation, join_dependency)
        else
          ActiveRecord::PostgreSQLCursor.new(self, cursor_name, relation)
        end
      end
  end

  class PostgreSQLCursor
    def initialize_with_rails(model, cursor_name, relation, join_dependency = nil)
      @relation = relation

      query = model.connection.unprepared_statement do
        relation.to_sql
      end

      initialize_without_rails(model, cursor_name, query, join_dependency)
    end
    alias_method_chain :initialize, :rails
  end
end

class ActiveRecord::Relation
  include ActiveRecord::CursorExtensions
end

class ActiveRecord::Base
  class << self
    delegate :cursor, :to => :all
  end
end
