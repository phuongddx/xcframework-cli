# XCFramework CLI - Code Standards & Conventions

**Last Updated:** February 15, 2026
**Scope:** Ruby implementation in lib/ and spec/

---

## Code Organization

### File Structure
```
lib/xcframework_cli/
├── cli/
│   ├── runner.rb              # Main Thor command class
│   └── commands/
│       ├── build.rb           # Build command
│       ├── spm.rb             # SPM command
│       └── init.rb            # Init command
├── builder/
├── config/
├── platform/
├── xcodebuild/
├── spm/
├── swift/
├── project/
├── utils/
├── errors.rb                  # Custom error hierarchy
└── version.rb                 # Version constant
```

### File Naming
- Use **snake_case** for filenames
- Match class name to file: `FooBar` → `foo_bar.rb`
- Group related classes in subdirectories

### Class Organization
```ruby
class Foo
  # 1. Constants
  TIMEOUT = 30

  # 2. Attribute accessors
  attr_reader :name
  attr_accessor :config

  # 3. Initialization
  def initialize(config)
    @config = config
  end

  # 4. Public methods
  def build
    # ...
  end

  # 5. Private methods
  private

  def helper_method
    # ...
  end
end
```

---

## Ruby Conventions

### Style Guide Basis
Follow **Rubocop** defaults (checked in CI):
- 2-space indentation (never tabs)
- 120-character line length (soft limit)
- snake_case for methods/variables
- PascalCase for classes/modules
- ALL_CAPS for constants

### Naming Conventions

| Type | Pattern | Example |
|------|---------|---------|
| Classes | PascalCase | `Builder::Orchestrator` |
| Modules | PascalCase | `XCFrameworkCLI::Utils` |
| Methods | snake_case | `execute_build` |
| Variables | snake_case | `config_file` |
| Constants | UPPER_SNAKE | `TIMEOUT_SECONDS` |
| Private methods | prefix `_` (optional) | `_validate_config` |
| Predicates | suffix `?` | `success?`, `valid?` |

### Documentation
Use single-line comments for code explanation:
```ruby
# Validate platform architecture support
platforms.each do |platform|
  unless platform.valid_architectures.include?(arch)
    raise InvalidArchitectureError
  end
end
```

Avoid excessive comments; write self-documenting code.

---

## Error Handling

### Custom Error Hierarchy
All errors inherit from `XCFrameworkCLI::Error`:

```ruby
module XCFrameworkCLI
  class Error < StandardError
    attr_reader :suggestions

    def initialize(message, suggestions: [])
      @suggestions = suggestions
      super(message)
    end
  end

  class ConfigError < Error; end
  class BuildError < Error; end
  class PlatformError < Error; end
end
```

### Raising Errors with Suggestions
```ruby
raise ValidationError.new(
  "Invalid platform: #{platform}",
  suggestions: [
    "Use 'ios' or 'ios-simulator'",
    "Run 'xckit platforms' for options"
  ]
)
```

### Error Display in CLI
```ruby
rescue XCFrameworkCLI::Error => e
  Logger.error(e.message)
  Logger.info("Suggestions:\n#{e.suggestions.map { |s| '  • ' + s }.join("\n")}")
  exit 1
end
```

---

## Logging Conventions

### Logger API
Use `Utils::Logger` singleton for all output:

```ruby
# Avoid: puts, print, STDOUT, STDERR
# Use instead:

Logger.debug("Debug info")        # Only if verbose
Logger.info("Informational")      # General output
Logger.success("Build complete")  # Positive outcome
Logger.warning("Check this")      # Non-blocking issue
Logger.error("Build failed")      # Critical failure
```

### Logger Configuration
```ruby
# Set in CLI
Logger.verbose = options[:verbose]
Logger.quiet = options[:quiet]

# Logger respects flags:
# verbose=true  → show debug messages
# quiet=true    → only show errors/success
```

### Test Logging
```ruby
# Logger is automatically suppressed in tests
# (see spec_helper.rb before/after hooks)

# In tests, Logger calls are safe and won't output
Logger.info("Test message")  # No output during tests
```

---

## Testing Standards

### RSpec Structure
```ruby
RSpec.describe ClassName do
  # 1. Use let for shared setup
  let(:dependency) { instance_double(Dependency) }
  let(:instance) { described_class.new(dependency) }

  # 2. Group by method
  describe '#method_name' do
    # 3. Group by condition
    context 'when condition is true' do
      before { allow(dep).to receive(:call).and_return(result) }

      it 'returns expected value' do
        expect(instance.method_name).to eq(expected)
      end
    end
  end
end
```

### Naming Test Files
```
lib/foo/bar.rb       → spec/unit/foo/bar_spec.rb
lib/utils/logger.rb  → spec/unit/utils/logger_spec.rb
```

### Mocking Patterns

**Pattern 1: Double with instance_double**
```ruby
let(:result) do
  instance_double(Xcodebuild::Result, success?: true, error_message: nil)
end

allow(Wrapper).to receive(:execute).and_return(result)
```

**Pattern 2: Class method stubbing**
```ruby
allow(Platform::Registry).to receive(:create).with('ios').and_return(ios_platform)
```

**Pattern 3: Filesystem operations**
```ruby
allow(File).to receive(:exist?).with(path).and_return(true)
allow(Dir).to receive(:glob).and_return(['/path/file'])
```

**Pattern 4: Shell command mocking**
```ruby
success_status = instance_double(Process::Status, success?: true)
allow(Open3).to receive(:capture3).and_return(['stdout', '', success_status])
```

### Coverage Requirements
- **Minimum:** 80% (enforced by SimpleCov)
- **Target:** 85%+
- **Skip in tests:** `ENV['SKIP_COVERAGE'] = 'true'` during development

### Test Isolation
```ruby
# Use let blocks, not instance variables
let(:config) { { build: { output_dir: 'build' } } }

# Create temp files/directories and clean up
Dir.mktmpdir('xckit-test') do |tmpdir|
  # Test code
end  # Auto-cleaned after block
```

---

## Configuration Management

### Schema Definition Pattern
```ruby
# config/schema.rb
module XCFrameworkCLI::Config
  class Schema
    def self.contract
      Dry::Validation.Contract do
        required(:project).schema do
          required(:name).filled(:string)
          required(:xcode_project).filled(:string)
        end

        optional(:build).schema do
          optional(:output_dir).filled(:string)
          optional(:configuration).filled(:string)
        end
      end
    end
  end
end
```

### Using Validated Config
```ruby
# Load and validate
contract = Config::Schema.contract
result = contract.call(raw_hash)

if result.failure?
  raise ValidationError.new(
    "Config validation failed",
    suggestions: result.errors.to_h.inspect
  )
end

validated_config = result.to_h
```

### Default Values
```ruby
# config/defaults.rb
OUTPUT_DIR = 'build'
CONFIGURATION = 'Release'
DEPLOYMENT_TARGET_IOS = '14.0'
CLEAN_BEFORE_BUILD = false
VERBOSE = false
```

---

## Platform Abstraction

### Base Class Interface
All platforms inherit from `Platform::Base` and implement class methods:

```ruby
class Platform::IOS < Base
  def self.platform_name
    'iOS'  # Human-readable
  end

  def self.platform_identifier
    'ios'  # Used in config files
  end

  def self.sdk_name
    'iphoneos'  # For xcodebuild -sdk
  end

  def self.destination
    'generic/platform=iOS'  # For xcodebuild -destination
  end

  def self.valid_architectures
    %w[arm64]  # Supported archs
  end

  def self.default_deployment_target
    '14.0'  # Minimum OS version
  end
end
```

### Platform Usage
```ruby
# Never instantiate directly
# ios_platform = Platform::IOS.new  # ❌ Wrong

# Use factory
ios_platform = Platform::Registry.create('ios')  # ✅ Correct

# Access class methods via instance
puts ios_platform.platform_name  # 'iOS'
```

---

## Build Pipeline Implementation

### Step Pattern
Each builder step follows this pattern:

```ruby
class Builder::MyStep
  def initialize(config)
    @config = config
  end

  def execute
    # Do work

    {
      success: true,
      data: result_data
    }
  rescue StandardError => e
    {
      success: false,
      error: e.message
    }
  end
end
```

### Orchestrator Integration
```ruby
# builder/orchestrator.rb
def build
  results = {}

  # Each step
  archive_result = Builder::Archiver.new(@config).execute
  results[:archive] = archive_result

  return results if !archive_result[:success]

  xcframework_result = Builder::XCFramework.new(@config).execute
  results[:xcframework] = xcframework_result

  results
end
```

---

## Shell Command Execution

### Command Wrapper Pattern
Always use helper methods; never call `system()` directly:

```ruby
# ❌ Don't do this
system("xcodebuild archive -project MyProject.xcodeproj")

# ✅ Do this
class Platform::Base
  def execute_command(cmd)
    stdout, stderr, status = Open3.capture3(cmd)
    raise BuildError.new(stderr) unless status.success?
    stdout
  end
end
```

### xcodebuild Integration
```ruby
# Use Xcodebuild::Wrapper
Xcodebuild::Wrapper.execute_archive(
  project: 'MyProject.xcodeproj',
  scheme: 'MyScheme',
  sdk: 'iphoneos',
  destination: 'generic/platform=iOS',
  archive_path: 'build/MyApp.xcarchive'
)

# Returns Xcodebuild::Result
# .success? → boolean
# .error_message → string (if failed)
```

---

## Version Management

### Semantic Versioning
Follow **semver.org**: MAJOR.MINOR.PATCH

```ruby
# lib/xcframework_cli/version.rb
module XCFrameworkCLI
  VERSION = '0.2.0'  # MAJOR.MINOR.PATCH
end
```

### Version Bumping Rules
- **MAJOR:** Breaking API changes (rare)
- **MINOR:** New features, non-breaking changes
- **PATCH:** Bug fixes only

---

## Common Patterns

### Configuration-Driven Behavior
```ruby
# Get value with fallback to default
config[:build][:output_dir] || 'build'

# Merge user settings with defaults
defaults = Config::Defaults::BUILD
user_config = config[:build] || {}
merged = defaults.merge(user_config)
```

### Collecting Errors
```ruby
errors = []

platforms.each do |platform|
  result = build_platform(platform)
  errors << result[:error] unless result[:success]
end

raise BuildError.new(errors.join(', ')) if errors.any?
```

### Progress Indication
```ruby
# Suppress in quiet mode, show spinners otherwise
Spinner.spin('Building archives...') do
  archive_platforms
end
```

---

## Security Considerations

### No Hardcoded Credentials
All configuration from files/environment:
```ruby
# ❌ Never hardcoded
API_KEY = 'secret_xyz'

# ✅ From environment or config
api_key = ENV['API_KEY'] || config[:publishing][:api_key]
```

### Path Validation
```ruby
# ❌ Untrusted user input
File.read(user_path)

# ✅ Validated first
raise FileNotFoundError unless File.exist?(user_path)
File.read(user_path)
```

### Safe Shell Execution
```ruby
# ✅ Use Wrapper (escapes arguments)
Xcodebuild::Wrapper.execute_archive(...)

# ❌ Don't concatenate strings
system("xcodebuild #{user_input}")  # Shell injection risk
```

---

## Code Quality Checklist

Before committing:

- [ ] No `puts` or `print` (use Logger)
- [ ] No direct `system()` calls (use Wrapper)
- [ ] No hardcoded paths or credentials
- [ ] Custom errors inherit from `XCFrameworkCLI::Error`
- [ ] Tests mirror source structure
- [ ] Tests mock external dependencies
- [ ] 80%+ coverage maintained
- [ ] Rubocop passes (`bundle exec rake rubocop`)
- [ ] Tests pass (`bundle exec rake spec`)

---

## Anti-Patterns (What NOT to Do)

| Anti-Pattern | Problem | Solution |
|--------------|---------|----------|
| `system()` calls | No error capture | Use Platform::Base#execute_command |
| `puts` output | Not mockable in tests | Use Logger |
| Direct platform instantiation | Violates abstraction | Use Platform::Registry.create |
| Hardcoded values | Not configurable | Use Config system |
| No error suggestions | Poor UX | Add suggestions to custom errors |
| Large files (>300 LOC) | Hard to maintain | Split into modules |
| Tight coupling | Hard to test/extend | Use dependency injection |

---

## Resources

- **Rubocop Config:** `.rubocop.yml` (enforced in CI)
- **Test Helper:** `spec/spec_helper.rb` (SimpleCov setup)
- **Integration Tests:** `spec/integration/` (requires ENV flag)
- **Example Config:** `config/examples/` (reference templates)

