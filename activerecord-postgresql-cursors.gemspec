# frozen_string_literal: true

require File.expand_path('lib/active_record/postgresql_cursors/version', __dir__)

Gem::Specification.new do |s|
  s.name = 'activerecord-postgresql-cursors'
  s.version = ActiveRecord::PostgreSQLCursors::VERSION

  s.required_rubygems_version = Gem::Requirement.new('>= 0') if s.respond_to? :required_rubygems_version=
  s.required_ruby_version = '>= 3.0'
  s.authors = ['J Smith']
  s.description = 'Provides some support for PostgreSQL cursors in ActiveRecord.'
  s.summary = s.description
  s.email = 'dark.panda@gmail.com'
  s.license = 'MIT'
  s.extra_rdoc_files = [
    'README.md'
  ]
  s.files = `git ls-files`.split($OUTPUT_RECORD_SEPARATOR)
  s.executables = s.files.grep(%r{^bin/}).map { |f| File.basename(f) }
  s.homepage = 'http://github.com/dark-panda/activerecord-postgresql-cursors'
  s.require_paths = ['lib']

  s.add_dependency('activerecord', ['>= 2.3'])
  s.metadata['rubygems_mfa_required'] = 'true'
end
