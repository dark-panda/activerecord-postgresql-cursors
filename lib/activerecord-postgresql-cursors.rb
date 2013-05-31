
module ActiveRecord
  # Exception raised when database cursors aren't supported, which they
  # absolutely should be in our app.
  class CursorsNotSupported < ActiveRecordError; end

  module PostgreSQLCursors
    module JoinDependency
      # Extra method we can use to clear out a couple of things in
      # JoinDependency so we can use some of the methods for our
      # cursors code.
      def clear_with_cursor
        @reflections            = []
        @base_records_hash      = {}
        @base_records_in_order  = []
      end
    end
  end

  # PostgreSQLCursor is an Enumerable class so you can use each, map,
  # any? and all of those nice Enumerable methods.
  #
  # At the moment, cursors aren't scrollable and are fetch forward-only
  # and read-only.
  #
  # This class isn't really meant to be used outside of the
  # ActiveRecord::Base#find method.
  class PostgreSQLCursor
    include Enumerable

    def initialize(model, cursor_name, query, join_dependency = nil)
      @model = model
      @cursor_name = if cursor_name
        @model.connection.quote_table_name(cursor_name.gsub(/"/, '\"'))
      end
      @query = query
      @join_dependency = join_dependency
    end

    def inspect
      %{#<ActiveRecord::PostgreSQLCursor cursor_name: "#{cursor_name}", query: "#{@query}">}
    end

    # Calls block once for each record in the cursor, passing that
    # record as a parameter.
    def each
      @model.transaction do
        begin
          declare_cursor
          if @join_dependency
            rows = Array.new
            last_id = nil
            while row = fetch_forward
              current_id = row[@join_dependency.join_base.aliased_primary_key]
              last_id ||= current_id
              if last_id == current_id
                rows << row
                last_id = current_id
              else
                yield @join_dependency.instantiate(rows).first
                @join_dependency.clear_with_cursor
                rows = [ row ]
              end
              last_id = current_id
            end

            if !rows.empty?
              yield @join_dependency.instantiate(rows).first
            end
          else
            while row = fetch_forward
              yield row
            end
          end
        ensure
          close_cursor
        end
      end
      nil
    end

    private
      def cursor_name
        @cursor_name ||= "cursor_#{(rand * 1000000).ceil}"
      end

      def fetch_forward #:nodoc:
        @model.find_by_sql(%{FETCH FORWARD FROM #{cursor_name}}).first
      end

      def declare_cursor #:nodoc:
        @model.connection.execute(%{DECLARE #{cursor_name} CURSOR FOR #{@query}})
      end

      def close_cursor #:nodoc:
        @model.connection.execute(%{CLOSE #{cursor_name}})
      end
  end
end

if ActiveRecord::VERSION::MAJOR >= 3
  require File.join(File.dirname(__FILE__), *%w{ active_record postgresql_cursors cursors })
else
  require File.join(File.dirname(__FILE__), *%w{ active_record postgresql_cursors cursors_2 })
end
