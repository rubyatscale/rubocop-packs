# Advanced Usage

## Pack-Level `.rubocop.yml` and `.rubocop_todo.yml` files
`rubocop-packs` also has some API that help you use rubocop in a pack-based context.

### Per-pack `.rubocop.yml`
While `rubocop-packs` can be used like any other `rubocop` by configuring in your top-level `.rubocop.yml` file, we also have a number of tools to support per-pack configuration.

To add a per-pack `.rubocop.yml`, you just need to create a `packs/your_pack/.rubocop.yml`. With this, each pack can specify an allow-listed set of cops (see below) that can be configured on a per-package level.

Example:
```yml
# packs/your_pack/.rubocop.yml
inherit_from: '../../.rubocop.yml'
```

### Per-pack `.rubocop_todo.yml`
To create a per-pack `.rubocop_todo.yml`, you can use the following API from `rubocop-packs`:
```ruby
RuboCop::Packs.regenerate_todo(packs: Packs.all)
```
This API will auto-generate a `packs/some_pack/.rubocop_todo.yml`. This allows a pack to own its own exception list.

### Configuration and Validation
To use per-pack `.rubocop.yml` and `.rubocop_todo.yml` files, you need to configure `rubocop-packs`:
```ruby
# config/rubocop_packs.rb
RuboCop::Packs.configure do |config|
  config.permitted_pack_level_cops = ['Packs/RootNamespaceIsPackName']
  config.required_pack_level_cops = ['Packs/RootNamespaceIsPackName']
end
```

The above two settings have associated validations that run with `RuboCop::Packs.validate`, which returns an array of errors. We recommend validating this in your test suite, for example:
```ruby
RSpec.describe 'rubocop-packs validations' do
  it { expect(RuboCop::Packs.validate).to be_empty }
end
```

Validations include:
- Ensuring that `packs/*/.rubocop_todo.yml` files only contain exceptions for the allow-list of `permitted_pack_level_cops`
- Ensuring that `packs/*/.rubocop.yml` files contain all of the cops listed in `required_pack_level_cops` and no other cops. This is to ensure that these files are only used to turn on and off an allow-list of cops, as most users would not want packs to configure most `rubocop` rules in a way that is different from the rest of the application.
