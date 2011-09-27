
ACTIVERECORD_GEM_VERSION = ENV['ACTIVERECORD_GEM_VERSION'] || '~> 3.0.3'

require 'rubygems'
gem 'activerecord', ACTIVERECORD_GEM_VERSION

require 'active_support'
require 'active_support/core_ext/module/aliasing'
require 'active_record'
require 'test/unit'
require 'logger'
require File.join(File.dirname(__FILE__), *%w{ .. lib activerecord-postgresql-cursors })

ActiveRecord::Base.logger = Logger.new("debug.log")
ActiveRecord::Base.configurations = {
  'arunit' => {
    :adapter => 'postgresql',
    :database => 'postgresql_cursors_unit_tests',
    :min_messages => 'warning',
    :schema_search_path => 'public'
  }
}

ActiveRecord::Base.establish_connection 'arunit'
ARBC = ActiveRecord::Base.connection

puts "Testing against ActiveRecord #{Gem.loaded_specs['activerecord'].version.to_s}"
if postgresql_version = ARBC.query('SELECT version()').flatten.to_s
  puts "PostgreSQL info from version(): #{postgresql_version}"
end

if !ARBC.table_exists?('foos')
  ActiveRecord::Migration.create_table(:foos) do |t|
    t.text :name
  end
end

if !ARBC.table_exists?('bars')
  ActiveRecord::Migration.create_table(:bars) do |t|
    t.text :name
    t.integer :foo_id
  end
end


class Bar < ActiveRecord::Base
  belongs_to :foo
end

class Foo < ActiveRecord::Base
  has_many :bars
end

module PostgreSQLCursorTestHelper
  def setup
    Foo.delete_all
    Bar.delete_all
    ARBC.execute(%{select setval('foos_id_seq', 1, false)})
    ARBC.execute(%{select setval('bars_id_seq', 1, false)})

    %w{ six seven eight nine ten eleven twelve thirteen fourteen fifteen }.each do |name|
      Bar.create(:name => name)
    end

    %w{ one two three four five }.each_with_index do |name, i|
      foo = Foo.new(:name => name)
      foo.bar_ids = [ i + 1, i + 6 ]
      foo.save
    end
  end
end
