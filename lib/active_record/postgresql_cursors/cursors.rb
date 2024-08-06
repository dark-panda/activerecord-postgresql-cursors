
module ActiveRecord
  module CursorExtensions
    extend ActiveSupport::Concern

    # Find using cursors. A PostgreSQLCursor object will be returned,
    # which can then be used as an Enumerable to loop through the
    # results.
    #
    # By default, cursor names are generated automatically using
    # "cursor_#{rand}", where rand is a big ol' random number that
    # is pretty unlikely to clash if you're using nested cursors.
    # Alternatively, you can supply a specific cursor name by
    # supplying a :cursor_name option.
    def cursor(*args)
      find_with_cursor('cursor', *args)
    end

    private

      def find_with_cursor(*args)
        options = args.extract_options!
        cursor_name = options.delete(:cursor_name)
        find_cursor(cursor_name, options)
      end

      # Find method for using cursors. This works just like the regular
      # ActiveRecord::Base#find_every method, except it returns a
      # PostgreSQLCursor object that can be used to loop through records.
      def find_cursor(cursor_name, options)
        unless connection.is_a? ActiveRecord::ConnectionAdapters::PostgreSQLAdapter
          raise CursorsNotSupported, "#{connection.class} doesn't support cursors"
        end

        relation = merge(options.slice(:readonly, :references, :order, :limit, :joins, :group, :having, :offset, :select, :uniq))
        including = (relation.eager_load_values + relation.includes_values).uniq

        if including.present?
          join_dependency = construct_join_dependency(joins_values, nil)
          join_relation = apply_join_dependency

          ActiveRecord::PostgreSQLCursor.new(self, cursor_name, join_relation, join_dependency)
        else
          ActiveRecord::PostgreSQLCursor.new(self, cursor_name, relation)
        end
      end
  end
end

class ActiveRecord::Relation
  include ActiveRecord::CursorExtensions
end

class ActiveRecord::Base
  class << self
    delegate :cursor, to: :all
  end
end
