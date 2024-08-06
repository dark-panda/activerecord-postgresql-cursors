# frozen_string_literal: true

guard 'minitest', test_folders: 'test', test_file_patterns: '*_tests.rb' do
  watch(%r{^test/(.+)_tests\.rb})

  watch(%r{^lib/(.*)([^/]+)\.rb}) do |_m|
    'test/cursor_tests.rb'
  end

  watch(%r{^test/test_helper\.rb}) do
    'test'
  end
end

instance_eval File.read('Guardfile.local') if File.exist?('Guardfile.local')
