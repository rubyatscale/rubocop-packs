# Packs

## Packs/ClassMethodsAsPublicApis

Enabled by default | Safe | Supports autocorrection | VersionAdded | VersionChanged
--- | --- | --- | --- | ---
Enabled | Yes | No | - | -

This cop states that public API should live on class methods, which are more easily statically analyzable,
searchable, and typically hold less state.

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
#### AcceptableParentClasses: [T::Enum, T::Struct, Struct, OpenStruct] (default)

```ruby
You can define `AcceptableParentClasses` which are a list of classes that, if inherited from, non-class methods are permitted.
This is useful when value objects are a part of your public API.

# good
# packs/foo/app/public/foo.rb
class Foo < T::Enum
  const :blah
end
```

### Configurable attributes

Name | Default value | Configurable values
--- | --- | ---
AcceptableParentClasses | `T::Enum`, `T::Struct`, `Struct`, `OpenStruct` | Array

## Packs/NamespacedUnderPackageName

Enabled by default | Safe | Supports autocorrection | VersionAdded | VersionChanged
--- | --- | --- | --- | ---
Disabled | Yes | No | - | -

This cop helps ensure that each pack exposes one namespace.

### Examples

```ruby
# bad
# packs/foo/app/services/blah/bar.rb
class Blah::Bar; end

# good
# packs/foo/app/services/foo/blah/bar.rb
class Foo::Blah::Bar; end
```

## Packs/RequireDocumentedPublicApis

Enabled by default | Safe | Supports autocorrection | VersionAdded | VersionChanged
--- | --- | --- | --- | ---
Disabled | Yes | No | - | -

No documentation

## Packs/TypedPublicApi

Enabled by default | Safe | Supports autocorrection | VersionAdded | VersionChanged
--- | --- | --- | --- | ---
Disabled | Yes | Yes  | - | -

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
