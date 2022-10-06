# Modularization

## Modularization/NamespacedUnderPackageName

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

## Modularization/TypedPublicApi

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
