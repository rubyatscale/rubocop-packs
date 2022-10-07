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
require: rubocop-packs
```

Alternatively, use the following array notation when specifying multiple extensions:

```yaml
require:
  - rubocop-other-extension
  - rubocop-packs
```

Now you can run `rubocop` and it will automatically load the RuboCop Packs cops together with the standard cops.

### Command line

```sh
rubocop --require rubocop-packs
```

### Rake task

```ruby
RuboCop::RakeTask.new do |task|
  task.requires << 'rubocop-packs'
end
```

## The Cops
All cops are located under [`lib/rubocop/cop/packs`](lib/rubocop/cop/packs), and contain examples/documentation.

In your `.rubocop.yml`, you may treat the Packs cops just like any other cop. For example:

```yaml
Packs/NamespacedUnderPackageName:
  Exclude:
    - lib/example.rb
```
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
