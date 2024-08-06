# frozen_string_literal: true

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

      @cursor_name = (@model.connection.quote_table_name(cursor_name.gsub('"', '\"')) if cursor_name)

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
        declare_cursor

        if @join_dependency
          rows = []
          last_id = nil

          until (row = fetch_forward).empty?
            instantiated_row = @join_dependency.instantiate(row, true).first
            current_id = instantiated_row[@join_dependency.send(:join_root).primary_key]
            last_id ||= current_id

            if last_id == current_id
              rows << row.first.values
              last_id = current_id
            else
              result_set = ActiveRecord::Result.new(row.columns, rows, row.column_types)

              yield @join_dependency.instantiate(result_set, true).first

              rows = [row.first.values]
            end

            last_id = current_id
          end

          unless rows.empty?
            result_set = ActiveRecord::Result.new(row.columns, rows, row.column_types)

            yield @join_dependency.instantiate(result_set, true).first
          end
        else
          until (row = fetch_forward).empty?
            yield @model.instantiate(row.first)
          end
        end
      ensure
        close_cursor
      end
      nil
    end

    private

      def cursor_name
        @cursor_name ||= "cursor_#{(rand * 1_000_000).ceil}"
      end

      def fetch_forward # :nodoc:
        @relation.uncached do
          @relation.connection.select_all(%{FETCH FORWARD FROM #{cursor_name}})
        end
      end

      def declare_cursor # :nodoc:
        @model.connection.execute(%{DECLARE #{cursor_name} CURSOR FOR #{@query}})
      end

      def close_cursor # :nodoc:
        @model.connection.execute(%{CLOSE #{cursor_name}})
      end
  end
end

require File.join(File.dirname(__FILE__), *%w{ active_record postgresql_cursors cursors })
