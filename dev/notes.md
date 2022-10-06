# Dev Notes

These are some notes to keep track of the development process of this gem.

Note that a lot of the TODOs here represent breaking changes. For now since we are at 0.0.1, we consider that to be okay as we want to prioritize improving the public API and getting it to something we feel good about.

# TODO
- Instead of using `ParsePackwerk`, use `Packs`
- We were unable to preserve the "incoming" nature of the namespace cop. That is -- when the cop is moved into this repo and controlled via `Include` and `Exclude`. If we want to add this back, we might consider a *separate* cop which runs on all files but only fails if the namespace is protected by a package that is included by the other cop?? Overall, I believe this incoming feature is valuable, but it's also solvable by having each pack conform to its own namespace.
- Add a test for TypedPublicApi so it uses the strict sigil but only applies to files in the public folder.
- It might be worth extracting ApplicationFixtureHelper out into a tiny little open source gem. It's small, but I'm constantly reusing it. I think it could live as something exportable from the packs gem which could help users create new packs?
- globally permitted namespace could be a configuration option of the cop so we don't need to load a custom thing.
- Turn on rubocop for this toolchain. Take from UsePackwerk, also add rubocop-sorbet for strict sigil cop
- Should this be rubocop-packs instead?
- Cops that depend on Stimpack should probably raise of `!defined?(Stimpack)`.
- For the Style/DocumentationMethod cop, should we monkey patch the existing one, like here: https://github.com/Shopify/rubocop-sorbet/blob/6634f033611604cd76eeb73eae6d8728ec82d504/lib/rubocop/cop/sorbet/mutable_constant_sorbet_aware_behaviour.rb or create our new cop?
- Modularization/NamespacedUnderPackageName? Or Modularization/SinglePackNamespace? Or Packs/SingleNamespace? 
