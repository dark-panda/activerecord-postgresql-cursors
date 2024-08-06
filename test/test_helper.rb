
require 'simplecov'

SimpleCov.command_name('Unit Tests')
SimpleCov.start do
  add_filter '/test/'
end

require 'rubygems'
require 'active_support'
require 'active_support/core_ext/module/aliasing'
require 'active_record'
require 'logger'
require 'minitest/autorun'
require 'minitest/reporters'

require File.join(File.dirname(__FILE__), *%w{ .. lib activerecord-postgresql-cursors })

ActiveRecord::Base.logger = Logger.new('debug.log') if ENV['ENABLE_LOGGER']

configurations = {}

%w{
  database.yml
  local_database.yml
}.each do |file|
  file = File.join('test', file)

  next unless File.exist?(file)

  configuration = YAML.safe_load(File.read(file))

  if configuration['arunit']
    configurations['arunit'] = configuration['arunit']
  end

  if defined?(JRUBY_VERSION) && configuration['jdbc']
    configurations['arunit'].merge!(configuration['jdbc'])
  end
end

ActiveRecord::Base.configurations = configurations
ActiveRecord::Base.establish_connection :arunit
ARBC = ActiveRecord::Base.connection

puts "Ruby version #{RUBY_VERSION}-p#{RUBY_PATCHLEVEL} - #{RbConfig::CONFIG['RUBY_INSTALL_NAME']}"
puts "Testing against ActiveRecord #{Gem.loaded_specs['activerecord'].version}"

postgresql_version = ARBC.select_rows('SELECT version()').flatten.to_s

if postgresql_version
  puts "PostgreSQL info from version(): #{postgresql_version}"
end

unless ARBC.data_source_exists?('foos')
  ActiveRecord::Migration.create_table(:foos) do |t|
    t.text :name
  end
end

unless ARBC.data_source_exists?('bars')
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
      Bar.create(name: name)
    end

    %w{ one two three four five }.each_with_index do |name, i|
      foo = Foo.new(name: name)
      foo.bar_ids = [ i + 1, i + 6 ]
      foo.save
    end
  end
end

Minitest::Reporters.use!(Minitest::Reporters::SpecReporter.new)
