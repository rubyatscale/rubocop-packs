# AGENTS.md

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
- `docs/` — auto-generated cop documentation (do not edit by hand)
- `tasks/` — Rake tasks for doc generation (only loaded when `VERIFYING_DOCUMENTATION=true`)
