# frozen_string_literal: true

require 'test_helper'

class PostgreSQLCursorTests < Minitest::Test
  include PostgreSQLCursorTestHelper

  def test_cursor_scoped
    cursor = Foo.cursor(order: 'id')

    assert_kind_of(ActiveRecord::PostgreSQLCursor, cursor)

    assert_equal(%w{ one two three four five }, cursor.collect(&:name))
  end

  def test_cursor_while_updating
    cursor = Foo.cursor(order: 'id')

    cursor.each do |row|
      row.name = "#{row.name}_updated"

      assert(row.save)
    end

    assert_equal(%w{ one_updated two_updated three_updated four_updated five_updated }, cursor.collect(&:name))
  end

  def test_with_associations
    cursor = Foo.cursor(order: 'id')

    cursor.each do |row|
      assert_kind_of(Foo, row)
      row.bars.each do |bar|
        assert_kind_of(Bar, bar)
      end
    end
  end

  def test_with_associations_eager_loading
    cursor = Foo.cursor(order: 'foos.id', include: :bars)

    cursor.each do |row|
      assert_kind_of(Foo, row)
      row.bars.each do |bar|
        assert_kind_of(Bar, bar)
      end
    end
  end

  def test_nested_cursors
    cursor = Foo.cursor(order: 'foos.id')

    cursor.each do |row|
      bars_cursor = row.bars.cursor

      assert_kind_of(ActiveRecord::PostgreSQLCursor, bars_cursor)

      bars_cursor.each do |bar|
        assert_kind_of(Bar, bar)
      end
    end
  end

  def test_as_relation
    cursor = Foo.order('foos.id').where('foos.id >= 3').cursor

    assert_equal(3, cursor.to_a.length)

    cursor.each do |row|
      assert_kind_of(Foo, row)
      assert_equal(2, row.bars.length)
      row.bars.each do |bar|
        assert_kind_of(Bar, bar)
      end
    end
  end

  def test_as_relation_with_associations
    cursor = Foo.includes(:bars).order('foos.id').where('foos.id >= 3').cursor

    assert_equal(3, cursor.to_a.length)

    cursor.each do |row|
      assert_kind_of(Foo, row)
      assert_equal(2, row.bars.length)
      row.bars.each do |bar|
        assert_kind_of(Bar, bar)
      end
    end
  end
end
