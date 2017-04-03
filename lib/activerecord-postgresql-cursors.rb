
module ActiveRecord
  # Exception raised when database cursors aren't supported, which they
  # absolutely should be in our app.
  class CursorsNotSupported < ActiveRecordError; end

  # PostgreSQLCursor is an Enumerable class so you can use each, map,
  # any? and all of those nice Enumerable methods.
  #
  # At the moment, cursors aren't scrollable and are fetch forward-only
  # and read-only.
  class PostgreSQLCursor
    include Enumerable

    def initialize(model, cursor_name, relation, join_dependency = nil)
      @model = model
      @relation = relation
      @join_dependency = join_dependency

      @cursor_name = if cursor_name
        @model.connection.quote_table_name(cursor_name.gsub(/"/, '\"'))
      end

      @query = model.connection.unprepared_statement do
        relation.to_sql
      end
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
              instantiated_row = @join_dependency.instantiate([row], @join_dependency.aliases).first

              current_id = instantiated_row[@join_dependency.join_root.primary_key]
              last_id ||= current_id
              if last_id == current_id
                rows << row
                last_id = current_id
              else
                yield @join_dependency.instantiate(rows, @join_dependency.aliases).first
                rows = [ row ]
              end
              last_id = current_id
            end

            if !rows.empty?
              yield @join_dependency.instantiate(rows, @join_dependency.aliases).first
            end
          else
            while row = fetch_forward
              yield @model.instantiate(row)
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
        @cursor_name ||= "cursor_#{(rand * 1_000_000).ceil}"
      end

      def fetch_forward #:nodoc:
        @relation.connection.select_all(%{FETCH FORWARD FROM #{cursor_name}}).first
      end

      def declare_cursor #:nodoc:
        @model.connection.execute(%{DECLARE #{cursor_name} CURSOR FOR #{@query}})
      end

      def close_cursor #:nodoc:
        @model.connection.execute(%{CLOSE #{cursor_name}})
      end
  end
end

require File.join(File.dirname(__FILE__), *%w{ active_record postgresql_cursors cursors })
