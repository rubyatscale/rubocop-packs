# rubocop-modularization

A collection of Rubocop rules for modularization..

## Installation

Just install the `rubocop-modularization` gem

```sh
gem install rubocop-modularization
```
or, if you use `Bundler`, add this line your application's `Gemfile`:

```ruby
gem 'rubocop-modularization', require: false
```

## Usage

You need to tell RuboCop to load the Modularization extension. There are three ways to do this:

### RuboCop configuration file

Put this into your `.rubocop.yml`:

```yaml
require: rubocop-modularization
```

Alternatively, use the following array notation when specifying multiple extensions:

```yaml
require:
  - rubocop-other-extension
  - rubocop-modularization
```

Now you can run `rubocop` and it will automatically load the RuboCop Modularization cops together with the standard cops.

### Command line

```sh
rubocop --require rubocop-modularization
```

### Rake task

```ruby
RuboCop::RakeTask.new do |task|
  task.requires << 'rubocop-modularization'
end
```

## The Cops
All cops are located under [`lib/rubocop/cop/modularization`](lib/rubocop/cop/modularization), and contain examples/documentation.

In your `.rubocop.yml`, you may treat the Modularization cops just like any other cop. For example:

```yaml
Modularization/NamespacedUnderPackageName:
  Exclude:
    - lib/example.rb
```
## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/rubyatscale/rubocop-modularization. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Code Of Conduct](CODE_OF_CONDUCT.MD).

To contribute a new cop, please use the supplied generator like this:

```sh
bundle exec rake new_cop[Modularization/NewCopName]
```

which will create a skeleton cop, a skeleton spec, an entry in the default config file and will require the new cop so that it is properly exported from the gem.

Don't forget to update the documentation with:

```sh
bundle exec rake generate_cops_documentation
```

## License

The gem is available as open source under the terms of the [MIT License](https://github.com/Shopify/rubocop-modularization/blob/main/LICENSE.txt).
