
if Rails::VERSION::MAJOR >= 3
  require File.join(File.dirname(__FILE__), 'postgresql_cursors_3')
else
  require File.join(File.dirname(__FILE__), 'postgresql_cursors_2')
end

