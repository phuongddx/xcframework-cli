# Testing Guide

**Minimum Coverage:** 80% (enforced by SimpleCov)

---

## Test Structure

Tests mirror the source code structure:

```
lib/xcframework_cli/builder/orchestrator.rb
spec/unit/builder/orchestrator_spec.rb
```

---

## Running Tests

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

## Coverage Reports

After running tests, coverage reports are generated in `coverage/index.html`

```bash
# Open coverage report
open coverage/index.html
```

---

## Mocking Patterns

### 1. Double Stubbing
```ruby
let(:result) do
  instance_double(Xcodebuild::Result, success?: true, error_message: nil)
end

allow(Wrapper).to receive(:execute).and_return(result)
```

### 2. Class Method Stubbing
```ruby
allow(Platform::Registry).to receive(:create).with('ios').and_return(ios_platform)
```

### 3. Filesystem Operations
```ruby
allow(File).to receive(:exist?).with(path).and_return(true)
allow(Dir).to receive(:glob).and_return(['/path/file'])
```

### 4. Shell Command Mocking
```ruby
success_status = instance_double(Process::Status, success?: true)
allow(Open3).to receive(:capture3).and_return(['stdout', '', success_status])
```

