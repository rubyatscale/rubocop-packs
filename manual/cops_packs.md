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

## Packs/NamespaceConvention

Enabled by default | Safe | Supports autocorrection | VersionAdded | VersionChanged
--- | --- | --- | --- | ---
Enabled | Yes | No | - | -

This cop helps ensure that each pack exposes one namespace.
Note that this cop doesn't necessarily expect you to be using stimpack (https://github.com/rubyatscale/stimpack),
but it does expect packs to live in the organizational structure as described in the README.md of that gem.

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
Enabled | Yes | No | - | -

This cop does two things:
1) It only activates for things in the public folder
2) It allows `Style/DocumentationMethod` to work with sigs as expected.

An alternate approach would be to monkey patch the existing cop, as `rubocop-sorbet` did here:
https://github.com/Shopify/rubocop-sorbet/blob/6634f033611604cd76eeb73eae6d8728ec82d504/lib/rubocop/cop/sorbet/mutable_constant_sorbet_aware_behaviour.rb
This monkey-patched cop could/should probably be upstreamed to `rubocop-sorbet`, and then `config/default.yml` could simply set `packs/*/app/public/**/*`
in the default include paths. However, that strategy has the downside of resulting in more configuration for the consumer if they only want to
support this for some packs.

## Packs/TypedPublicApi

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
