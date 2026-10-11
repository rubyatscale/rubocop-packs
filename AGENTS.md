This file provides guidance to AI coding agents when working with code in this repository.

## What this project is

`rubocop-packs` is a collection of RuboCop cops for Ruby applications modularized with the [packs](https://github.com/rubyatscale/packs) standard. The cops enforce conventions like correct pack structure, dependency declarations, and public API boundaries.

## Commands

```bash
bundle install

# Run all tests (RSpec) + generate cop documentation
bundle exec rake

# Run only specs
bundle exec rspec

# Run a single spec file
bundle exec rspec spec/path/to/spec.rb

# Run specs against the minimum supported rubocop, as CI does
BUNDLE_GEMFILE=gemfiles/rubocop_minimum.gemfile bundle install
BUNDLE_GEMFILE=gemfiles/rubocop_minimum.gemfile bundle exec rspec

# Lint
bundle exec rubocop
bundle exec rubocop -a  # auto-correct

# Type checking (Sorbet)
bundle exec srb tc

# Regenerate cop documentation (after changing cop descriptions)
VERIFYING_DOCUMENTATION=true bundle exec rake generate_cops_documentation
```

## Architecture

- `lib/rubocop/cop/packs/` — individual RuboCop cop classes; each file is one cop
- `lib/rubocop-packs.rb` — registers all cops with RuboCop
- `spec/rubocop/cop/packs/` — RSpec tests for each cop using `RuboCop::RSpec::ExpectOffense` helpers
- `manual/` — auto-generated cop documentation (do not edit by hand; regenerate from the cops' YARD comments)
- `docs/` — hand-written guides
- `tasks/` — Rake tasks for doc generation (only loaded when `VERIFYING_DOCUMENTATION=true`)

## Type annotations

Sorbet checks types statically from [RBS comments](https://sorbet.org/docs/rbs-support), enabled in `sorbet/config`. The gem does not depend on sorbet-runtime.

- Signatures go above the method (`#: (String name) -> bool`); type assertions trail the expression (`x = [] #: Array[String]`).
- `#: as !nil` does nothing at runtime. Prefer code Sorbet can narrow, such as `fetch(0)` instead of `first`, or an `else` branch that raises.
- Do not add `sig` blocks, `extend T::Sig`, `T::Struct`, `T.let`, or other runtime `T` APIs. The `Sorbet/Forbid*` cops in `.rubocop.yml` catch the common ones. To convert existing code, `bundle exec spoom srb sigs translate` rewrites `sig` blocks and `bundle exec spoom srb assertions translate` rewrites `T.let`, `T.must` and `T.cast`.
- Avoid `untyped` except as a hash value type. Use the real type, or `top` when a value can be anything; Sorbet makes you narrow `top` before using it.
