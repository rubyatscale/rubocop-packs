# Packs

## Packs/ClassMethodsAsPublicApis

Enabled by default | Safe | Supports autocorrection | VersionAdded | VersionChanged
--- | --- | --- | --- | ---
Disabled | Yes | No | - | -

This cop states that public API should live on class methods, which are more easily statically analyzable,
searchable, and typically hold less state.

Options:

* `AcceptableParentClasses`: A list of classes that, if inherited from, non-class methods are permitted (useful when value objects are a part of your public API)

### Examples

```ruby
# bad
# packs/foo/app/public/foo.rb
module Foo
  def blah
  end
end

# good
# packs/foo/app/public/foo.rb
module Foo
  def self.blah
  end
end
```

### Configurable attributes

Name | Default value | Configurable values
--- | --- | ---
AcceptableParentClasses | `T::Enum`, `T::Struct`, `Struct`, `OpenStruct` | Array
FailureMode | `default` | String

## Packs/DocumentedPublicApis

Enabled by default | Safe | Supports autocorrection | VersionAdded | VersionChanged
--- | --- | --- | --- | ---
Enabled | Yes | No | - | -

This cop helps ensure that each pack has a documented public API
The following examples assume this basic setup.

### Examples

```ruby
# bad
# packs/foo/app/public/foo.rb
class Foo
  def bar; end
end

# packs/foo/app/public/foo.rb
class Foo
  # This is a documentation comment.
  # It can live below or below a sorbet type signature.
  def bar; end
end
```

### Configurable attributes

Name | Default value | Configurable values
--- | --- | ---
FailureMode | `default` | String

## Packs/RootNamespaceIsPackName

Enabled by default | Safe | Supports autocorrection | VersionAdded | VersionChanged
--- | --- | --- | --- | ---
Enabled | Yes | No | - | -

This cop helps ensure that each pack exposes one namespace.
Note that this cop doesn't necessarily expect you to be using stimpack (https://github.com/rubyatscale/stimpack),
but it does expect packs to live in the organizational structure as described in the README.md of that gem.

This allows packs to opt in and also prevent *other* files from sitting in their namespace.

### Examples

```ruby
# bad
# packs/foo/app/services/blah/bar.rb
class Blah::Bar; end

# good
# packs/foo/app/services/foo/blah/bar.rb
class Foo::Blah::Bar; end
```

### Configurable attributes

Name | Default value | Configurable values
--- | --- | ---
FailureMode | `default` | String

## Packs/TypedPublicApis

Enabled by default | Safe | Supports autocorrection | VersionAdded | VersionChanged
--- | --- | --- | --- | ---
Enabled | Yes | Yes  | - | -

This cop helps ensure that each pack's public API is strictly typed, enforcing strong boundaries.

### Examples

```ruby
# bad
# packs/foo/app/public/foo.rb
# typed: false
module Foo; end

# good
# packs/foo/app/public/foo.rb
# typed: strict
module Foo; end
```

### Configurable attributes

Name | Default value | Configurable values
--- | --- | ---
FailureMode | `default` | String
