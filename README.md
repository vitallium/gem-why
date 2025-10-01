# gem-why

A RubyGems plugin that shows which installed gems depend on a specific gem. Similar to `yarn why` or `npm why`.

## Quick Start

```bash
# Install the plugin
gem install gem-why

# Find all dependency chains to rake (default - shows transitive dependencies)
gem why rake

# Show only direct dependencies
gem why rake --direct

# Visualize dependencies as a tree
gem why rake --tree
```

## Why Deep by Default?

Unlike most dependency tools that show only direct dependencies by default, `gem why` defaults to **deep dependency analysis** because:

- **Most real-world scenarios** involve transitive dependencies - you typically want to know "why is this gem even installed?" not just "what directly depends on it?"
- **Debugging is easier** when you see the full chain immediately - you can trace exactly how a problematic gem entered your dependency tree
- **Mirrors `yarn why`** behavior - the inspiration for this tool also defaults to showing full dependency chains
- **Direct lookups are still fast** - use `--direct` when you specifically need just immediate dependents

## Installation

Install the gem by executing:

```bash
gem install gem-why
```

The plugin will automatically be available as a `gem` command after installation.

## Feature Comparison

| Mode | Command | Shows | Best For |
|------|---------|-------|----------|
| **Deep** (default) | `gem why GEMNAME` | Full dependency chains with paths | Understanding transitive dependencies |
| **Direct** | `gem why GEMNAME --direct` | Only direct dependencies | Quick lookup of immediate dependents |
| **Tree** | `gem why GEMNAME --tree` | Visual tree structure | Complex dependency visualization |

## Usage

To see which gems depend on a specific gem:

```bash
gem why GEMNAME [options]
```

### Examples

#### Default Behavior - Deep Dependencies

Show all dependency chains leading to a gem (including transitive dependencies):

```bash
$ gem why concurrent-ruby
Dependency chains leading to concurrent-ruby:

  rails => activesupport => concurrent-ruby
    └─ rails (8.0.3) requires activesupport = 8.0.3
      └─ activesupport (8.0.3) requires concurrent-ruby ~> 1.0, >= 1.3.1

  actionpack => activesupport => concurrent-ruby
    └─ actionpack (8.0.3) requires activesupport = 8.0.3
      └─ activesupport (8.0.3) requires concurrent-ruby ~> 1.0, >= 1.3.1

Total: 10 root gem(s) depend on concurrent-ruby
Found 25 dependency chain(s)

Tip: Use --direct for direct dependencies only or --tree for a visual tree
```

#### Direct Dependencies Only

Check which gems directly depend on `rake`:

```bash
$ gem why rake --direct
Gems that depend on rake:

  ast (2.4.3) requires rake ~> 13.2
  minitest (5.16.0) requires rake >= 0
  rubocop (1.21.0) requires rake >= 0
  ...

Total: 15 gem(s)
```

#### Tree Visualization

Display dependencies as a visual tree:

```bash
$ gem why concurrent-ruby --tree
Dependency tree for concurrent-ruby:

rails (8.0.3)
├── activesupport = 8.0.3
│   └── activesupport (8.0.3) requires concurrent-ruby ~> 1.0, >= 1.3.1
│       └── concurrent-ruby ✓

actionpack (8.0.3)
├── activesupport = 8.0.3
│   └── activesupport (8.0.3) requires concurrent-ruby ~> 1.0, >= 1.3.1
│       └── concurrent-ruby ✓

Total: 10 root gem(s) depend on concurrent-ruby
```

If no gems depend on the specified gem:

```bash
$ gem why nonexistent-gem
No gems depend on nonexistent-gem
```

### Options

| Option | Short | Description |
|--------|-------|-------------|
| (none) | | Show full dependency chains (default) |
| `--direct` | `-d` | Show only direct dependencies |
| `--tree` | `-t` | Display as a visual tree |
| `--help` | `-h` | Show help message |
| `--verbose` | `-V` | Verbose output |

## How It Works

### Default Mode (Deep Dependencies)

1. Builds a complete dependency graph of all installed gems
2. Finds all paths (dependency chains) leading to the target gem
3. Shows transitive dependencies (A depends on B, B depends on target)
4. Groups results by root gems
5. Displays the full chain: `root => intermediate => target`

### Direct Mode (`--direct`)

1. Scans all installed gems on your system
2. Checks both runtime and development dependencies
3. Finds which gems **directly** depend on the specified gem
4. Displays results with gem names, versions, and requirements
5. Results are sorted alphabetically for easy reading

### Tree Mode (`--tree`)

1. Performs deep dependency analysis
2. Builds a hierarchical tree structure
3. Visualizes dependencies using tree characters (├──, └──, │)
4. Shows the complete dependency path from root to target
5. Makes it easy to understand complex dependency relationships

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
