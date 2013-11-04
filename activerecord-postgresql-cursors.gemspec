# -*- encoding: utf-8 -*-

require File.expand_path('../lib/active_record/postgresql_cursors/version', __FILE__)

Gem::Specification.new do |s|
  s.name = "activerecord-postgresql-cursors"
  s.version = ActiveRecord::PostgreSQLCursors::VERSION

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["J Smith"]
  s.description = "Provides some support for PostgreSQL cursors in ActiveRecord."
  s.summary = s.description
  s.email = "code@zoocasa.com"
  s.license = "MIT"
  s.extra_rdoc_files = [
    "README.rdoc"
  ]
  s.files = `git ls-files`.split($\)
  s.executables = s.files.grep(%r{^bin/}).map { |f| File.basename(f) }
  s.test_files = s.files.grep(%r{^(test|spec|features)/})
  s.homepage = "http://github.com/zoocasa/activerecord-postgresql-cursors"
  s.require_paths = ["lib"]

  s.add_dependency("activerecord", [">= 2.3"])
end

