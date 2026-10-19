# Agent instructions

## Always bump the version

Every change to this repo must include a version bump. A merged PR releases the version in `VERSION`.
If the version does not change, users do not get your change.

1. Run `meta/bump` with no argument to print the current version.
2. Run `meta/bump {new version}`. This updates `VERSION` and `formula/ih-core.rb` together.
   It does not commit or push.
3. Commit the two files in the same PR as your change.

Do not edit `VERSION` or the `VERSION=` line in `formula/ih-core.rb` by hand. `meta/bump` keeps the two in sync.
See "How to release a new version" in [README.md](./README.md).
