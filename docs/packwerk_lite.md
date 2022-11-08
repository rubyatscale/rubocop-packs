# [PackwerkLite](/lib/rubocop/cop/packwerk_lite)

This is a proof-of-concept for Packwerk Lite, an implementation of Packwerk that is made simpler by assuming the application adheres to [`Packs/RootNamespaceIsPackName`](/lib/rubocop/cop/packs/namespace_convention.rb).

[`PackwerkLite/Privacy`](/lib/rubocop/cop/packwerk_lite/privacy_checker.rb)

[`PackwerkLite/Dependency`](/lib/rubocop/cop/packwerk_lite/dependency_checker.rb)

At Gusto, this was able to detect 7% of privacy and 8% of dependency violations that packwerk could detect. See appendix if you are curious how it performs in your codebase.

This tool cannot ever replace packwerk because it doesn't serve those who are first beginning to break up a large app into packages and cannot (and should not) try to change their namespacing prematurely. Packwerk also has more first-class support for essential concepts like its custom-formatted TODO list (`deprecated_references.yml`) and custom error messages to support more user-friendly feedback and developer ergonomics. Packwerk also detects cycles in stated dependencies along with a number of other features.
  
So why would we want to do this...?
- As a thought experiment and conversation starter! This was created during a Gusto Modularity Hackathon.
- As a learning tool! As a simple version of packwerk I was hoping it could serve as a basic model for how packwerk works.
- Experimentally and hypothetically, as a way to provide early feedback loop for engineers who are more familiar with rubocop

What is missing?
- In order to run this, we need to read from AND write to `deprecated_references.yml` file so that they pick up and ignore the same things (right now we only read from). We'd likely also need to expose a validation to allow the client to confirm that the `**/.rubocop_todo.yml` entries for `PackwerkLite/Privacy` and `PackwerkLite/Dependency` are empty.
- There were very few false positives (things this picked up that `packwerk` did not) in Gusto's codebase, but we'd want to address those too.

# Appendix

If you want to see how effective it is at your org, try this:
## Count your violations
```ruby
all_violations = ParsePackwerk.all.map{|p| ParsePackwerk::DeprecatedReferences.for(p).violations }
privacy_count = all_violations.select(&:privacy?).flat_map(&:files).count
dependency_count = all_violations.select(&:dependency?).flat_map(&:files).count
```
## Run rubocop
```
bundle exec rubocop --only=PackwerkLite/Privacy,PackwerkLite/Dependency --out tmp/results.txt
```

Copy the results into a file
```ruby
lines = File.read('tmp/results.txt').split("\n")
lines.select{|l| l.include?('Privacy violation detected') }.map{|f| f.match(/^.*?.rb/)[0] }.count
lines.select{|l| l.include?('Dependency violation detected') }.map{|f| f.match(/^.*?.rb/)[0] }.count
```
