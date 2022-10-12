# PackwerkLite

## PackwerkLite/Dependency

Enabled by default | Safe | Supports autocorrection | VersionAdded | VersionChanged
--- | --- | --- | --- | ---
Disabled | Yes | No | - | -

This cop helps ensure that packs are depending on packs explicitly.

### Examples

```ruby
# bad
# packs/foo/app/services/foo.rb
class Foo
  def bar
    Bar
  end
end

# packs/foo/package.yml
# enforces_dependencies: true
# enforces_privacy: false
# dependencies:
#   - packs/baz

# good
# packs/foo/app/services/foo.rb
class Foo
  def bar
    Bar
  end
end

# packs/foo/package.yml
# enforces_dependencies: true
# enforces_privacy: false
# dependencies:
#   - packs/baz
#   - packs/bar
```

## PackwerkLite/Privacy

Enabled by default | Safe | Supports autocorrection | VersionAdded | VersionChanged
--- | --- | --- | --- | ---
Disabled | Yes | No | - | -

This cop helps ensure that packs are using public API of other systems
The following examples assume this basic setup.

### Examples

```ruby
# packs/bar/app/public/bar.rb
class Bar
  def my_public_api; end
end

# packs/bar/app/services/private.rb
class Private
  def my_private_api; end
end

# packs/bar/package.yml
# enforces_dependencies: false
# enforces_privacy: true

# bad
# packs/foo/app/services/foo.rb
class Foo
  def bar
    Private.my_private_api
  end
end

# good
# packs/foo/app/services/foo.rb
class Bar
  def bar
    Bar.my_public_api
  end
end
```
