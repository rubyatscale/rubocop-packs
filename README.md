# rubocop-packs

A collection of Rubocop rules for modularizing ruby applications that conform to the `packs` standard.

## Installation

Just install the `rubocop-packs` gem

```sh
gem install rubocop-packs
```
or, if you use `Bundler`, add this line your application's `Gemfile`:

```ruby
gem 'rubocop-packs', require: false
```

## Usage

You need to tell RuboCop to load the Packs extension. There are three ways to do this:

### RuboCop configuration file

Put this into your `.rubocop.yml`:

```yaml
require:
  - rubocop-packs
```

Now you can run `rubocop` and it will automatically load the RuboCop Packs cops together with the standard cops.

## The Cops
All cops are located under [`lib/rubocop/cop/packs`](lib/rubocop/cop/packs), and contain examples/documentation.

In your `.rubocop.yml`, you may treat the Packs cops just like any other cop. For example:

```yaml
Packs/RootNamespaceIsPackName:
  Exclude:
    - lib/example.rb
```

## Pack-Level `.rubocop.yml` and `.rubocop_todo.yml` files
`rubocop-packs` also has some API that help you use rubocop in a pack-based context.

### Per-pack `.rubocop.yml`
While `rubocop-packs` can be used like any other `rubocop` by configuring in your top-level `.rubocop.yml` file, we also have a number of tools to support per-pack configuration.

To add a per-pack `.rubocop.yml`, you just need to create a `packs/your_pack/.rubocop.yml` and then include:
```yml
inherit_from: '../../.rubocop.yml'
```

Note though that inherited paths are relative to your pack-level `.rubocop.yml`. To avoid that, you can rename your `.rubocop.yml` to `.inherited_rubocop.yml`, set `.rubocop.yml` to:
```
inherit_from: '.inherited_rubocop.yml'
```
And then similarly change the `inherit_from` in `packs/your_pack/.rubocop.yml`.

### Per-pack `.rubocop_todo.yml`
To create a per-pack `.rubocop_todo.yml`, you can use the following API from `rubocop-packs`:
```ruby
RuboCop::Packs.auto_generate_rubocop_todo(packs: ParsePackwerk.all)
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

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/rubyatscale/rubocop-packs. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Code Of Conduct](CODE_OF_CONDUCT.MD).

To contribute a new cop, please use the supplied generator like this:

```sh
bundle exec rake new_cop[Packs/NewCopName]
```

which will create a skeleton cop, a skeleton spec, an entry in the default config file and will require the new cop so that it is properly exported from the gem.

Don't forget to update the documentation with:

```sh
VERIFYING_DOCUMENTATION=1 bundle exec rake generate_cops_documentation
```

## License

The gem is available as open source under the terms of the [MIT License](https://github.com/Shopify/rubocop-packs/blob/main/LICENSE.txt).
