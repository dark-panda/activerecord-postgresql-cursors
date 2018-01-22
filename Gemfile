source 'https://rubygems.org'

gemspec

if RUBY_PLATFORM == "java"
  gem "activerecord-jdbcpostgresql-adapter"
else
  gem "pg", '~> 0.21'
end

gem "rdoc"
gem "rake"
gem "minitest"
gem "minitest-reporters"
gem "guard-minitest"
gem "simplecov"

if File.exists?('Gemfile.local')
  instance_eval File.read('Gemfile.local')
end

