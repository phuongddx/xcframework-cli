# Contributing to XCFramework CLI

Thank you for your interest in contributing! This guide will help you get started with development, testing, and submitting contributions.

---

## 📋 Table of Contents

- [Getting Started](#getting-started)
- [Development Workflow](#development-workflow)
- [Code Style Guidelines](#code-style-guidelines)
- [Testing Conventions](#testing-conventions)
- [Commit Message Convention](#commit-message-convention)
- [Pull Request Process](#pull-request-process)
- [Architecture Guidelines](#architecture-guidelines)
- [Common Development Tasks](#common-development-tasks)

---

## 🚀 Getting Started

### Prerequisites

- **macOS** 11.0 or later
- **Ruby** 3.0 or later
- **Xcode** 13.0+ with command line tools
- **Bundler** - Install with `gem install bundler`

### Initial Setup

```bash
# Clone the repository
git clone https://github.com/phuongddx/xcframework-cli.git
cd xcframework-cli

# Install dependencies
bundle install

# Run tests to verify setup
bundle exec rake spec

# Start interactive console
bundle exec rake console
```

---

## 🔄 Development Workflow

### 1. Create a Feature Branch

```bash
git checkout -b feature/your-feature-name
# or
git checkout -b fix/your-bug-fix
```

### 2. Make Your Changes

- Write code following our [Code Style Guidelines](#code-style-guidelines)
- Add tests for new functionality
- Update documentation as needed

### 3. Run Tests & Linting

```bash
# Run all tests with coverage (requires 80% minimum)
bundle exec rake spec

# Run tests without coverage requirement
bundle exec rake test

# Run specific test file
bundle exec rspec spec/unit/builder/orchestrator_spec.rb

# Lint code
bundle exec rake rubocop

# Auto-fix linting issues
bundle exec rake lint_fix

# Run all checks (tests + linting)
bundle exec rake
```

### 4. Commit Your Changes

```bash
git add .
git commit -m "feat: add your feature description"
```

See [Commit Message Convention](#commit-message-convention) for details.

### 5. Push and Create Pull Request

```bash
git push origin feature/your-feature-name
```

Then open a Pull Request on GitHub.

---

## 🎨 Code Style Guidelines

### Ruby Style

We follow [RuboCop](https://rubocop.org/) style guidelines:

- **Indentation**: 2 spaces (no tabs)
- **Line length**: Max 120 characters
- **String literals**: Double quotes for interpolation, single quotes otherwise
- **Method naming**: Snake case (`my_method`)
- **Class naming**: Camel case (`MyClass`)
- **Constants**: Upper snake case (`MY_CONSTANT`)

### Best Practices

**DO:**
```ruby
# Good: Use explicit return values
def build
  {
    success: true,
    xcframework_path: path
  }
end

# Good: Use meaningful variable names
def archive_for_platform(platform)
  archive_path = File.join(output_dir, "#{platform.name}.xcarchive")
  # ...
end

# Good: Use logger for output
Utils::Logger.info("Building framework...")
```

**DON'T:**
```ruby
# Bad: Using puts/print directly
puts "Building framework..."

# Bad: Single-letter variable names
def build(p)
  a = p.name
  # ...
end

# Bad: Missing error handling
def build
  # No error checking
end
```

### Module Organization

```ruby
module XCFrameworkCLI
  module Builder
    class Orchestrator
      # Public methods first
      def build(config)
        # ...
      end

      private

      # Private methods last
      def validate_config(config)
        # ...
      end
    end
  end
end
```

---

## 🧪 Testing Conventions

### Test Structure

Tests mirror the source code structure:
```
lib/xcframework_cli/builder/orchestrator.rb
spec/unit/builder/orchestrator_spec.rb
```

### Writing Tests

Use RSpec with `describe`/`context`/`it` blocks:

```ruby
require 'spec_helper'

RSpec.describe XCFrameworkCLI::Builder::Orchestrator do
  let(:config) { double('config', output_dir: '/tmp/build') }
  let(:orchestrator) { described_class.new(config) }

  describe '#build' do
    context 'when build succeeds' do
      it 'returns success with xcframework path' do
        result = orchestrator.build

        expect(result[:success]).to be true
        expect(result[:xcframework_path]).to be_a(String)
      end
    end

    context 'when build fails' do
      before do
        allow(orchestrator).to receive(:archive).and_raise(BuildError)
      end

      it 'returns failure with error message' do
        result = orchestrator.build

        expect(result[:success]).to be false
        expect(result[:error]).to be_present
      end
    end
  end
end
```

### Mocking External Commands

Always mock external commands (xcodebuild, swift, etc.):

```ruby
RSpec.describe XCFrameworkCLI::Swift::Builder do
  describe '#build' do
    before do
      allow(Open3).to receive(:capture3).and_return(['', '', double(success?: true)])
    end

    it 'calls swift build with correct arguments' do
      builder.build

      expect(Open3).to have_received(:capture3).with(
        a_string_including('swift build')
      )
    end
  end
end
```

### Coverage Requirements

- **Minimum coverage**: 80%
- **SimpleCov** generates reports in `coverage/index.html`
- Skip coverage requirement: `ENV['SKIP_COVERAGE'] = 'true'`

### Running Tests

```bash
# All tests with coverage
bundle exec rake spec

# All tests without coverage requirement
bundle exec rake test

# Specific test file
bundle exec rspec spec/unit/builder/orchestrator_spec.rb

# Specific test example
bundle exec rspec spec/unit/builder/orchestrator_spec.rb:42

# Integration tests (requires example project)
RUN_INTEGRATION_TESTS=1 bundle exec rspec spec/integration/
```

---

## 📝 Commit Message Convention

We follow [Conventional Commits](https://www.conventionalcommits.org/):

### Format

```
<type>(<scope>): <subject>

<body>

<footer>
```

### Types

- `feat:` - New feature
- `fix:` - Bug fix
- `docs:` - Documentation changes
- `test:` - Test changes
- `refactor:` - Code refactoring (no functionality change)
- `style:` - Code style changes (formatting, whitespace)
- `perf:` - Performance improvements
- `chore:` - Maintenance tasks (dependencies, build)

### Examples

```bash
# Feature
git commit -m "feat: add resource bundle support for SPM builds"

# Bug fix
git commit -m "fix: resolve symlinks in resource bundles"

# Documentation
git commit -m "docs: update architecture guide with resource bundle flow"

# Refactoring
git commit -m "refactor: extract platform registry to separate class"

# With scope and body
git commit -m "feat(spm): add multi-arch framework slicing

- Implement lipo-based framework combining
- Add symlink resolution for distribution
- Update tests for multi-arch scenarios"
```

### Commit Best Practices

**DO:**
- Use present tense ("add feature" not "added feature")
- Use imperative mood ("move file" not "moves file")
- Keep subject line under 72 characters
- Reference issues/PRs in footer (`Closes #123`)

**DON'T:**
- End subject line with period
- Include WIP commits in PRs (squash them)
- Make commits too large (break into logical pieces)

---

## 🔀 Pull Request Process

### Before Submitting

1. ✅ All tests pass (`bundle exec rake spec`)
2. ✅ Code linting passes (`bundle exec rake rubocop`)
3. ✅ Coverage meets 80% minimum
4. ✅ Documentation updated (if applicable)
5. ✅ CHANGELOG.md updated (if applicable)

### PR Title

Use the same convention as commit messages:
```
feat: add resource bundle support
fix: resolve symlink issues in frameworks
docs: update contributing guide
```

### PR Description Template

```markdown
## Description
Brief description of changes

## Changes Made
- Change 1
- Change 2
- Change 3

## Testing
- [ ] Unit tests added/updated
- [ ] Integration tests pass
- [ ] Manual testing performed

## Screenshots (if applicable)
[Add screenshots for visual changes]

## Related Issues
Closes #123
Related to #456

## Checklist
- [ ] Tests pass
- [ ] Linting passes
- [ ] Documentation updated
- [ ] CHANGELOG.md updated
```

### Review Process

1. **Automated checks**: GitHub Actions run tests and linting
2. **Code review**: Maintainers review code and provide feedback
3. **Revisions**: Make requested changes
4. **Approval**: Maintainer approves PR
5. **Merge**: Maintainer merges PR

---

## 🏗️ Architecture Guidelines

### Module Hierarchy

All code lives under `XCFrameworkCLI` module:

```ruby
module XCFrameworkCLI
  module Builder     # Build orchestration
  module CLI         # Command-line interface
  module Config      # Configuration loading/validation
  module Platform    # Platform definitions
  module SPM         # Swift Package Manager support
  module Swift       # Swift build helpers
  module Xcodebuild  # Xcode tool wrappers
  module Utils       # Utilities
end
```

### Critical Patterns

#### 1. Error Handling

All custom errors inherit from `XCFrameworkCLI::Error`:

```ruby
raise ValidationError.new(
  "Invalid platform: #{platform}",
  suggestions: [
    "Use 'ios' or 'ios-simulator'",
    "Run 'xckit platforms' to see all options"
  ]
)
```

#### 2. Platform Abstraction

All platforms inherit from `Platform::Base`:

```ruby
module XCFrameworkCLI
  module Platform
    class IOS < Base
      def self.platform_name
        'iOS'
      end

      def self.sdk_name
        'iphoneos'
      end

      # ... other required methods
    end
  end
end
```

#### 3. Command Execution

Always use platform wrappers for shell commands:

```ruby
# Good
platform.execute_command(cmd)

# Bad
system(cmd)
`#{cmd}`
```

#### 4. Logging

Use `Utils::Logger` for all output:

```ruby
# Good
Utils::Logger.info("Building framework...")
Utils::Logger.success("Build completed!")
Utils::Logger.error("Build failed")

# Bad
puts "Building framework..."
```

### Adding New Features

#### Adding a New Platform

1. Create `lib/xcframework_cli/platform/[platform_name].rb`
2. Inherit from `Platform::Base`
3. Implement all required class methods
4. Register in `Platform::Registry`
5. Add tests in `spec/unit/platform/[platform_name]_spec.rb`

#### Adding a New Build Step

1. Create module under `Builder::` (e.g., `Builder::ResourceManager`)
2. Initialize with config hash
3. Implement main action method
4. Return hash with `:success` boolean
5. Integrate into `Builder::Orchestrator` pipeline
6. Add unit tests

#### Adding Configuration Options

1. Update `Config::Schema` validation rules
2. Update `Config::Defaults` with defaults
3. Update example configs in `config/examples/`
4. Add tests in `spec/unit/config/loader_spec.rb`
5. Document in `docs/CONFIGURATION.md`

---

## 🛠️ Common Development Tasks

### Interactive Console

```bash
bundle exec rake console

# Example usage:
> Platform::Registry.all_platforms
> Config::Loader.load(path: 'config/examples/basic.yml')
> builder = Builder::Orchestrator.new(config)
```

### Running Integration Tests

```bash
# Requires example project (Example/SwiftyBeaver/)
RUN_INTEGRATION_TESTS=1 bundle exec rspec spec/integration/

# With verbose output
RUN_INTEGRATION_TESTS=1 bundle exec rspec spec/integration/ --format documentation
```

### Debugging

Use `pry` for debugging:

```ruby
require 'pry'

def problematic_method
  # Add breakpoint
  binding.pry

  # Code execution will pause here
  result = some_calculation
  result
end
```

### Code Coverage

```bash
# Generate coverage report
bundle exec rake spec

# Open coverage report in browser
open coverage/index.html
```

### Performance Profiling

```ruby
require 'benchmark'

Benchmark.bm do |x|
  x.report("build:") { orchestrator.build }
end
```

---

## 📚 Key Reference Documents

- **[ARCHITECTURE.md](ARCHITECTURE.md)** - System architecture
- **[ARCHITECTURE_OVERVIEW.md](ARCHITECTURE_OVERVIEW.md)** - Detailed design
- **[CLAUDE.md](../CLAUDE.md)** - AI assistant guide
- **[CONFIGURATION.md](CONFIGURATION.md)** - Configuration options

---

## ❓ Getting Help

- **Issues**: [GitHub Issues](https://github.com/phuongddx/xcframework-cli/issues)
- **Discussions**: [GitHub Discussions](https://github.com/phuongddx/xcframework-cli/discussions)
- **Documentation**: [docs/](.)

---

## 📄 License

By contributing, you agree that your contributions will be licensed under the same license as the project.

---

**Last Updated**: December 9, 2025
**Thank you for contributing!** 🎉
