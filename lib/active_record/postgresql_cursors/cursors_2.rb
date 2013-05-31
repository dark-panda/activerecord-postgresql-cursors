
module ActiveRecord
  class Base
    class << self
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
      def find_with_cursors *args
        if args.first.to_s == 'cursor'
          options = args.extract_options!
          cursor_name = options.delete(:cursor_name)
          validate_find_options(options)
          set_readonly_option!(options)
          find_cursor(cursor_name, options)
        else
          find_without_cursors(*args)
        end
      end
      alias_method_chain :find, :cursors

      def cursor(*args)
        find(:cursor, *args)
      end
    end

    private
      # Find method for using cursors. This works just like the regular
      # ActiveRecord::Base#find_every method, except it returns a
      # PostgreSQLCursor object that can be used to loop through records.
      def self.find_cursor(cursor_name, options)
        unless connection.is_a? ActiveRecord::ConnectionAdapters::PostgreSQLAdapter
          raise CursorsNotSupported, "#{connection.class} doesn't support cursors"
        end

        catch :invalid_query do
          if options[:include]
            join_dependency = ActiveRecord::Associations::ClassMethods::JoinDependency.new(self, merge_includes(scope(:find, :include), options[:include]), options[:joins])
            return ActiveRecord::PostgreSQLCursor.new(
              self,
              cursor_name,
              construct_finder_sql_with_included_associations(
                options,
                join_dependency
              ),
              join_dependency
            )
          else
            return ActiveRecord::PostgreSQLCursor.new(
              self,
              cursor_name,
              construct_finder_sql(
                options
              )
            )
          end
        end
        nil
      end
  end

  class PostgreSQLCursor
    def initialize_with_rails_2(model, cursor_name, query, join_dependency = nil)
      initialize_without_rails_2(model, cursor_name, query, join_dependency)
    end
    alias_method_chain :initialize, :rails_2
  end
end
