# Advanced Usage

## Pack-Level `package_rubocop.yml` and `package_rubocop_todo.yml` files
`rubocop-packs` also has some API that help you use rubocop in a pack-based context.

### Basic Configuration
In your top-level `.rubocop.yml` file, you'll want to include configuration from `rubocop-packs`:
```yml
inherit_gem:
  rubocop-packs:
    - config/default.yml
    - config/pack_config.yml
```

This is the mechanism by which pack level rubocop files are incorporated into the top-level config.

### Per-pack `package_rubocop.yml`
While `rubocop-packs` can be used like any other `rubocop` by configuring in your top-level `.rubocop.yml` file, we also have a number of tools to support per-pack configuration.

To add a per-pack `package_rubocop.yml`, you just need to create a `packs/your_pack/package_rubocop.yml`. With this, each pack can specify an allow-listed set of cops (see below) that can be configured on a per-package level.

### Per-pack `package_rubocop_todo.yml`
To create a per-pack `package_rubocop_todo.yml`, you can use the following API from `rubocop-packs`:
```ruby
RuboCop::Packs.regenerate_todo(packs: Packs.all)
```
This API will auto-generate a `packs/some_pack/package_rubocop_todo.yml`. This allows a pack to own its own exception list.

### Configuration and Validation
To use per-pack `package_rubocop.yml` and `package_rubocop_todo.yml` files, you need to configure `rubocop-packs`:
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
- Ensuring that `packs/*/package_rubocop_todo.yml` files only contain exceptions for the allow-list of `permitted_pack_level_cops`
- Ensuring that `packs/*/package_rubocop.yml` files contain all of the cops listed in `required_pack_level_cops` and no other cops. This is to ensure that these files are only used to turn on and off an allow-list of cops, as most users would not want packs to configure most `rubocop` rules in a way that is different from the rest of the application.
