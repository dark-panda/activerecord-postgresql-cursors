# frozen_string_literal: true

require 'rubygems'
require 'rubygems/package_task'
require 'rake/testtask'
require 'rdoc/task'
require 'bundler/gem_tasks'

$LOAD_PATH.push File.expand_path(File.dirname(__FILE__), 'lib')

version = ActiveRecord::PostgreSQLCursors::VERSION

desc 'Test PostgreSQL extensions'
Rake::TestTask.new(:test) do |t|
  t.libs << "#{File.dirname(__FILE__)}/test"
  t.test_files = FileList['test/**/*_test.rb']
  t.verbose = !!ENV['VERBOSE_TESTS']
  t.warning = !!ENV['WARNINGS']
end

task default: :test

desc 'Build docs'
Rake::RDocTask.new do |t|
  t.title = "ActiveRecord PostgreSQL Cursors #{version}"
  t.main = 'README.md'
  t.rdoc_dir = 'doc'
  t.rdoc_files.include('README.rdoc', 'MIT-LICENSE', 'lib/**/*.rb')
end
