
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

    attr_accessor :cursor_name

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
    def each(rows_per_slice=nil,&block)
      call_method(:each, rows_per_slice, &block)
    end

    def each_slice(rows_per_slice,&block)
      call_method(:each_slice, rows_per_slice, rows_per_slice, &block)
    end

    def call_method(method_to_call, rows_per_slice, *args, &block)
      @model.transaction do
        begin
          declare_cursor
          if @join_dependency
            rows = Array.new
            last_id = nil
            until (fetched_rows = fetch_forward(rows_per_slice)).empty?
              fetched_rows.each do |row|
                current_id = row[@join_dependency.join_base.aliased_primary_key]
                last_id ||= current_id
                if last_id == current_id
                  rows << row
                  last_id = current_id
                else
                  @join_dependency.instantiate(rows).send(method_to_call,*args, &block)
                  @join_dependency.clear_with_cursor
                  rows = [ row ]
                end
                last_id = current_id
              end
            end

            if !rows.empty?
              @join_dependency.instantiate(rows).send(method_to_call,*args, &block)
            end
          else
            until (fetched_rows = fetch_forward(rows_per_slice)).empty?
              fetched_rows.send(method_to_call,*args, &block)
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

      def fetch_forward(rows_per_slice = nil) #:nodoc:
        @model.find_by_sql(%{FETCH FORWARD #{rows_per_slice} FROM #{cursor_name}})
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
  require File.join(File.dirname(__FILE__), 'postgresql_cursors_3')
else
  require File.join(File.dirname(__FILE__), 'postgresql_cursors_2')
end
