# Dev Notes

These are some notes to keep track of the development process of this gem.

Note that a lot of the TODOs here represent breaking changes. For now since we are at 0.0.1, we consider that to be okay as we want to prioritize improving the public API and getting it to something we feel good about.

# TODO
- Instead of using `ParsePackwerk`, use `Packs`
- Add a test for TypedPublicApi so it uses the strict sigil but only applies to files in the public folder.
- It might be worth extracting ApplicationFixtureHelper out into a tiny little open source gem. It's small, but I'm constantly reusing it. I think it could live as something exportable from the packs gem which could help users create new packs?
