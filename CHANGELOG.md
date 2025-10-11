# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.0.2] - 2025-10-11

### Fixed

- Add spec memoization to improve performance of recursive analysis
- Fix terminology: use 'dependents' instead of 'dependencies' in help text
- Eliminate redundant spec lookups by passing version from analyze

## [0.0.1] - 2025-10-01

### Added

- Initial release of `gem-why` plugin
- `gem why GEMNAME` command to show which installed gems depend on a specific gem
- Display gem names, versions, and version requirements for dependencies
- Alphabetically sorted output for easy scanning
- Clear messaging when no dependencies are found
- **Deep dependency tracking** - traverse the full dependency tree to find transitive dependencies (DEFAULT)
- **Tree visualization** with `--tree` option - display dependencies as a visual tree with proper indentation
- `--direct` option to show only direct dependencies (for quick lookups)
- Comprehensive test suite with 16 test cases
- RuboCop compliance with default settings
- Complete documentation in README

[0.0.1]: https://github.com/vitaly/gem-why/releases/tag/v0.0.1
