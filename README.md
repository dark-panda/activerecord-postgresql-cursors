# ActiveRecord PostgreSQL Cursors

This extension allows you to loop through record sets using cursors in an
Enumerable fashion. This allows you to cut down memory usage by only pulling
in individual records on each loop rather than pulling everything into
memory all at once.

To use a cursor, just change the first parameter to an
ActiveRecord::Base.find to :cursor instead of :first or :all or
whatever or use the ActiveRecord::Base.cursor method directly.

```ruby
MyModel.find(:cursor, :conditions => 'some_column = true').each do |r|
  puts r.inspect
end

MyModel.find(:cursor).collect { |r| r.foo / PI }.avg

MyModel.cursor.each do |r|
  puts r.inspect
end
```

All ActiveRecord::Base.find options are available and should work as-is.
As a bonus, the PostgreSQLCursor object returned includes Enumerable,
so you can iterate to your heart's content.

This extension should work with Rails 6.1+. For older versions of Rails, try
out older versions of the gem.

At the moment, this is a non-scrollable cursor -- it will only fetch
forward. Also note that these cursors are non-updateable/insensitive to
updates to the underlying data. You can write to the records themselves,
but changes outside of the cursor's transaction will not affect the
data being retrieved from the point of the cursor's creation, or rather
more specifically from the time you begin iterating.

The cursor itself is wrapped in a transaction as is required by PostgreSQL
and the cursor name is automatically generated using random numbers or
a name supplied during cursor creation. On raised SQL exceptions, the
transaction is ABORTed and the cursor CLOSEd.

Associations are handled, so you can use :include in your find options. Of
course, this requires some nonsense when moving the cursor around, but it
works all the same. In some cases, pre-loading and eager loading of
associations and whatnot creates an initial query that will grab the initial
IDs of the model being fetched and then create the actual cursor query out
of those large joins that ActiveRecord sometimes generates. This larger
query will be the query that's wrapped in the transaction and in a cursor,
while the first query is just used to build the larger joined query. This
allows for a brief window between the point that the cursor query is
created and the time it is executed. In these cases, it may be wise to wrap
your use or cursors in your own transaction to ensure that changes made to
the underlying data don't interfere with your cursor's visibility.

## License

This gem is licensed under an MIT-style license. See the +MIT-LICENSE+ file for
details.
