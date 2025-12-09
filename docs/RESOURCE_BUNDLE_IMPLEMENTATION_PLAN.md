# Resource Bundle Implementation Plan

## 🎯 Objective
Implement resource bundle handling for SPM builds to support frameworks that use `Bundle.module` for accessing resources (images, xibs, localization files, etc.).

## 🔍 Problem Statement

**Current State**: xcframework-cli SPM implementation **will fail** for packages with resources because:
1. Swift Package Manager generates `resource_bundle_accessor.swift` that expects resources at runtime in app bundle
2. Binary frameworks place resources in `Frameworks/<Target>.framework/<Bundle>`
3. Without override, `Bundle.module` looks in wrong location → **CRASH** ❌

**Solution**: Override the resource bundle accessor to search in framework bundle location (like xccache does)

---

## 📋 Implementation Tasks

### **Phase 1: Research & Setup** (2 hours)

#### Task 1.1: Understand Resource Bundle Behavior
- [ ] Read SPM resource bundle documentation
- [ ] Study xccache implementation:
  - `/tmp/xccache/lib/xccache/spm/xcframework/slice.rb` (lines 14-47)
  - `/tmp/xccache/tools/templates/resource_bundle_accessor.*`
- [ ] Understand when SPM generates `resource_bundle_accessor.swift`
- [ ] Test current behavior with `epost-ios-theme-ui` if it has resources

**Key Files to Study**:
```ruby
# xccache reference
/tmp/xccache/lib/xccache/spm/xcframework/slice.rb:14-47
  - override_resource_bundle_accessor
  - copy_resource_bundles
  - resolve_resource_symlinks
```

**Learning Outcomes**:
- How `Bundle.module` works in SPM
- Where `.bundle` files are created during `swift build`
- Template variables needed for override

---

### **Phase 2: Template Creation** (1 hour)

#### Task 2.1: Create Swift Resource Bundle Accessor Template
**File**: `config/templates/resource_bundle_accessor.swift`

```swift
// config/templates/resource_bundle_accessor.swift
import Foundation
#if canImport(CoreFoundation)
import CoreFoundation
#endif

private class BundleFinder {}

extension Foundation.Bundle {
    /// Returns the resource bundle associated with the current Swift module.
    static var module: Bundle = {
        let bundleName = "{{PACKAGE_NAME}}_{{TARGET_NAME}}"

        let candidates = [
            // Bundle should be present in app bundle
            Bundle.main.resourceURL,
            // Bundle should be present in framework bundle
            Bundle(for: BundleFinder.self).resourceURL,
            // For command-line tools
            Bundle.main.bundleURL,
            // Add search in Frameworks directory for binary targets
            Bundle(for: BundleFinder.self).resourceURL?.deletingLastPathComponent().deletingLastPathComponent(),
        ]

        for candidate in candidates {
            let bundlePath = candidate?.appendingPathComponent(bundleName + ".bundle")
            if let bundle = bundlePath.flatMap(Bundle.init(url:)) {
                return bundle
            }
        }

        fatalError("unable to find bundle named {{PACKAGE_NAME}}_{{TARGET_NAME}}")
    }()
}
```

**Variables**:
- `{{PACKAGE_NAME}}`: Package name (from Package.swift)
- `{{TARGET_NAME}}`: Target name
- `{{MODULE_NAME}}`: C99-compatible module name

#### Task 2.2: Create Objective-C Resource Bundle Accessor Template
**File**: `config/templates/resource_bundle_accessor.m`

```objc
// config/templates/resource_bundle_accessor.m
#import <Foundation/Foundation.h>

NSBundle* {{MODULE_NAME}}_SWIFTPM_MODULE_BUNDLE() {
    NSString *bundleName = @"{{PACKAGE_NAME}}_{{TARGET_NAME}}";

    NSArray *candidates = @[
        [NSBundle mainBundle].resourceURL,
        [[NSBundle bundleForClass:[NSObject class]] resourceURL],
        [NSBundle mainBundle].bundleURL,
    ];

    for (NSURL *candidate in candidates) {
        NSURL *bundleURL = [candidate URLByAppendingPathComponent:[bundleName stringByAppendingString:@".bundle"]];
        NSBundle *bundle = [NSBundle bundleWithURL:bundleURL];
        if (bundle != nil) {
            return bundle;
        }
    }

    @throw [NSException exceptionWithName:@"BundleNotFoundException"
                                   reason:[NSString stringWithFormat:@"Unable to find bundle named %@", bundleName]
                                 userInfo:nil];
}
```

**Template System Integration**:
```ruby
# lib/xcframework_cli/utils/template.rb
TEMPLATE_VARS = {
  'PACKAGE_NAME' => :package_name,
  'TARGET_NAME' => :target_name,
  'MODULE_NAME' => :module_name
}
```

---

### **Phase 3: Resource Bundle Detection** (2 hours)

#### Task 3.1: Add Resource Bundle Detection to SPM::Package
**File**: `lib/xcframework_cli/spm/package.rb`

Add methods:
```ruby
# Detect if target has resource bundle
#
# @param target_name [String] Target name
# @return [Boolean] True if target has resources
def has_resource_bundle?(target_name)
  # Check if resource bundle exists in build products
  bundle_path = resource_bundle_path(target_name)
  File.exist?(bundle_path)
end

# Get resource bundle path for target
#
# @param target_name [String] Target name
# @return [String] Path to resource bundle
def resource_bundle_path(target_name)
  # Format: <package_name>_<target_name>.bundle
  bundle_name = "#{name}_#{target_name}"
  File.join(package_dir, '.build', 'debug', "#{bundle_name}.bundle")
end

# Get resource bundle name
#
# @param target_name [String] Target name
# @return [String] Bundle name
def resource_bundle_name(target_name)
  "#{name}_#{target_name}"
end
```

#### Task 3.2: Parse Package.swift for Resources
Add `swift package dump-package` parsing:
```ruby
# Parse package manifest
#
# @return [Hash] Package metadata
def package_manifest
  @package_manifest ||= begin
    cmd = ['swift', 'package', 'dump-package', '--package-path', package_dir]
    require 'open3'
    stdout, stderr, status = Open3.capture3(*cmd)

    if status.success?
      require 'json'
      JSON.parse(stdout, symbolize_names: true)
    else
      Utils::Logger.error("Failed to parse Package.swift: #{stderr}")
      {}
    end
  end
end

# Check if target has resources in manifest
#
# @param target_name [String] Target name
# @return [Boolean] True if target declares resources
def target_has_resources?(target_name)
  targets = package_manifest[:targets] || []
  target_data = targets.find { |t| t[:name] == target_name }
  return false unless target_data

  resources = target_data[:resources] || []
  !resources.empty?
end
```

---

### **Phase 4: Resource Bundle Override in FrameworkSlice** (3 hours)

#### Task 4.1: Add Resource Bundle Compilation Step
**File**: `lib/xcframework_cli/spm/framework_slice.rb`

Add new method:
```ruby
# Override resource bundle accessor for binary framework
# This ensures Bundle.module works correctly in binary targets
#
# @return [void]
def override_resource_bundle_accessor
  return unless has_resource_bundle?

  Utils::Logger.info("Overriding resource_bundle_accessor for binary framework")

  # Determine language (Swift or ObjC)
  template_name = use_clang? ? 'resource_bundle_accessor.m' : 'resource_bundle_accessor.swift'

  # Create override source file
  source_path = File.join(tmpdir, File.basename(template_name))
  obj_path = File.join(products_dir, "#{module_name}.build", "#{File.basename(source_path)}.o")

  # Render template
  Utils::Template.render(
    template_name,
    {
      PACKAGE_NAME: package_name,
      TARGET_NAME: target,
      MODULE_NAME: module_name
    },
    save_to: source_path
  )

  # Compile to object file
  compile_resource_accessor(source_path, obj_path)
end

# Compile resource bundle accessor to object file
#
# @param source_path [String] Source file path
# @param obj_path [String] Output object file path
# @return [void]
def compile_resource_accessor(source_path, obj_path)
  FileUtils.mkdir_p(File.dirname(obj_path))

  if use_clang?
    # Compile Objective-C
    cmd = [
      'xcrun', 'clang',
      '-x', 'objective-c',
      '-target', sdk.triple(with_version: true),
      '-isysroot', sdk.sdk_path,
      '-o', obj_path,
      '-c', source_path
    ]
  else
    # Compile Swift
    cmd = [
      'xcrun', 'swiftc',
      '-emit-library', '-emit-object',
      '-module-name', module_name,
      '-target', sdk.triple(with_version: true),
      '-sdk', sdk.sdk_path,
      '-o', obj_path,
      source_path
    ]
  end

  Utils::Logger.debug("Compiling resource accessor: #{cmd.join(' ')}")
  require 'open3'
  stdout, stderr, status = Open3.capture3(*cmd)

  unless status.success?
    raise Error, "Failed to compile resource accessor: #{stderr}"
  end

  Utils::Logger.debug("Resource accessor compiled: #{obj_path}")
end

# Check if target uses Clang (C/ObjC) vs Swift
#
# @return [Boolean] True if using Clang
def use_clang?
  # For now, assume Swift. Can be enhanced by checking target type
  # from Package.swift manifest
  false
end

# Check if target has resource bundle
#
# @return [Boolean] True if resource bundle exists
def has_resource_bundle?
  resource_bundle_path.exist?
end

# Get resource bundle path
#
# @return [Pathname] Path to resource bundle
def resource_bundle_path
  bundle_name = "#{package_name}_#{target}"
  Pathname.new(products_dir) / "#{bundle_name}.bundle"
end

# Get package name
#
# @return [String] Package name
def package_name
  @package_name ||= File.basename(package_dir, '.*')
end
```

#### Task 4.2: Integrate Override into Build Process
Update `create_framework_structure`:
```ruby
def create_framework_structure
  Utils::Logger.debug("Creating framework structure at #{output_path}")

  # Ensure output directory exists
  FileUtils.mkdir_p(File.dirname(output_path))
  FileUtils.mkdir_p(output_path)

  # IMPORTANT: Override resource accessor BEFORE creating binary
  # This ensures the .o file is included in libtool
  override_resource_bundle_accessor if has_resource_bundle?

  # Create framework components
  create_framework_binary
  create_info_plist
  create_headers
  create_modules

  # Copy resource bundle to framework
  copy_resource_bundle if has_resource_bundle?
end
```

---

### **Phase 5: Resource Bundle Copying** (2 hours)

#### Task 5.1: Implement Resource Bundle Copy
Add to `lib/xcframework_cli/spm/framework_slice.rb`:

```ruby
# Copy resource bundle to framework
#
# @return [void]
def copy_resource_bundle
  return unless has_resource_bundle?

  Utils::Logger.info("Copying resource bundle to framework")

  bundle_path = resource_bundle_path
  dest_path = File.join(output_path, bundle_path.basename)

  # Resolve symlinks before copying
  resolve_resource_symlinks(bundle_path)

  # Copy bundle
  FileUtils.cp_r(bundle_path, dest_path)
  Utils::Logger.debug("Copied resource bundle: #{bundle_path.basename}")
end

# Resolve symlinks in resource bundle
# SPM may create symlinks that need to be resolved for binary distribution
#
# @param bundle_path [Pathname] Path to resource bundle
# @return [void]
def resolve_resource_symlinks(bundle_path)
  Utils::Logger.debug("Resolving symlinks in resource bundle")

  # Find all symlinks in bundle
  symlinks = Dir.glob(File.join(bundle_path, '**', '*')).select do |path|
    File.symlink?(path)
  end

  symlinks.each do |symlink_path|
    begin
      # Get real path
      real_path = File.realpath(symlink_path)

      # Remove symlink
      File.delete(symlink_path)

      # Copy real file/directory
      if File.directory?(real_path)
        FileUtils.cp_r(real_path, symlink_path)
      else
        FileUtils.cp(real_path, symlink_path)
      end

      Utils::Logger.debug("Resolved symlink: #{File.basename(symlink_path)}")
    rescue StandardError => e
      Utils::Logger.warning("Failed to resolve symlink #{symlink_path}: #{e.message}")
    end
  end
end
```

---

### **Phase 6: Testing** (3 hours)

#### Task 6.1: Unit Tests
**File**: `spec/unit/spm/framework_slice_resource_spec.rb`

```ruby
# frozen_string_literal: true

require 'spec_helper'
require 'tmpdir'

RSpec.describe XCFrameworkCLI::SPM::FrameworkSlice do
  describe 'resource bundle handling' do
    let(:tmpdir) { Dir.mktmpdir }
    let(:package_dir) { File.join(tmpdir, 'TestPackage') }
    let(:products_dir) { File.join(package_dir, '.build', 'arm64-apple-ios-simulator', 'release') }
    let(:sdk) do
      instance_double(
        XCFrameworkCLI::Swift::SDK,
        name: :iphonesimulator,
        triple: 'arm64-apple-ios-simulator',
        sdk_path: '/path/to/sdk',
        version: '15.0',
        'triple': 'arm64-apple-ios-simulator',
        swiftc_args: []
      )
    end

    subject(:slice) do
      described_class.new(
        target: 'MyTarget',
        sdk: sdk,
        package_dir: package_dir,
        output_path: File.join(tmpdir, 'MyTarget.framework'),
        tmpdir: tmpdir
      )
    end

    before do
      FileUtils.mkdir_p(products_dir)
      FileUtils.mkdir_p(File.join(products_dir, 'MyTarget.build'))
    end

    after do
      FileUtils.rm_rf(tmpdir)
    end

    describe '#has_resource_bundle?' do
      context 'when resource bundle exists' do
        before do
          bundle_path = File.join(products_dir, 'TestPackage_MyTarget.bundle')
          FileUtils.mkdir_p(bundle_path)
        end

        it 'returns true' do
          expect(slice.send(:has_resource_bundle?)).to be true
        end
      end

      context 'when resource bundle does not exist' do
        it 'returns false' do
          expect(slice.send(:has_resource_bundle?)).to be false
        end
      end
    end

    describe '#override_resource_bundle_accessor' do
      before do
        # Create resource bundle
        bundle_path = File.join(products_dir, 'TestPackage_MyTarget.bundle')
        FileUtils.mkdir_p(bundle_path)
      end

      it 'creates Swift resource accessor override' do
        expect(XCFrameworkCLI::Utils::Template).to receive(:render).with(
          'resource_bundle_accessor.swift',
          hash_including(:PACKAGE_NAME, :TARGET_NAME, :MODULE_NAME),
          save_to: match(/resource_bundle_accessor\.swift$/)
        )

        allow(slice).to receive(:compile_resource_accessor)

        slice.send(:override_resource_bundle_accessor)
      end

      it 'compiles the accessor to object file' do
        allow(XCFrameworkCLI::Utils::Template).to receive(:render)

        expect(slice).to receive(:compile_resource_accessor).with(
          match(/resource_bundle_accessor\.swift$/),
          match(/\.o$/)
        )

        slice.send(:override_resource_bundle_accessor)
      end
    end

    describe '#copy_resource_bundle' do
      let(:bundle_path) { File.join(products_dir, 'TestPackage_MyTarget.bundle') }
      let(:output_path) { File.join(tmpdir, 'MyTarget.framework') }

      before do
        FileUtils.mkdir_p(bundle_path)
        FileUtils.mkdir_p(output_path)
        File.write(File.join(bundle_path, 'test.txt'), 'test')
      end

      it 'copies bundle to framework' do
        slice.send(:copy_resource_bundle)

        expect(File.exist?(File.join(output_path, 'TestPackage_MyTarget.bundle'))).to be true
        expect(File.exist?(File.join(output_path, 'TestPackage_MyTarget.bundle', 'test.txt'))).to be true
      end
    end

    describe '#resolve_resource_symlinks' do
      let(:bundle_path) { Pathname.new(File.join(tmpdir, 'test.bundle')) }

      before do
        FileUtils.mkdir_p(bundle_path)

        # Create real file
        real_file = File.join(tmpdir, 'real_file.txt')
        File.write(real_file, 'content')

        # Create symlink
        symlink = File.join(bundle_path, 'symlink.txt')
        File.symlink(real_file, symlink)
      end

      it 'resolves symlinks to real files' do
        expect(File.symlink?(File.join(bundle_path, 'symlink.txt'))).to be true

        slice.send(:resolve_resource_symlinks, bundle_path)

        symlink_path = File.join(bundle_path, 'symlink.txt')
        expect(File.symlink?(symlink_path)).to be false
        expect(File.read(symlink_path)).to eq 'content'
      end
    end
  end
end
```

#### Task 6.2: Integration Test
**File**: `spec/integration/spm_resources_spec.rb`

Create test package with resources:
```ruby
# Create test SPM with resources
# Build xcframework
# Verify Bundle.module works in framework
```

---

### **Phase 7: Documentation** (1 hour)

#### Task 7.1: Update CLAUDE.md
Add resource bundle section:
```markdown
### Resource Bundle Support
SPM frameworks with resources are fully supported. The build process:
1. Detects resource bundles in build products
2. Overrides `Bundle.module` accessor for binary framework compatibility
3. Resolves symlinks in resources
4. Copies bundle to framework

Resources are automatically handled for targets that declare:
```swift
// Package.swift
.target(
    name: "MyTarget",
    resources: [.process("Resources")]
)
```

#### Task 7.2: Add Example Config
**File**: `config/examples/spm_with_resources.yml`

```yaml
spm:
  package_dir: "Example/PackageWithResources"
  targets: ["MyUIKit"]
  platforms: [ios, ios-simulator]
  library_evolution: true

build:
  output_dir: "./build"
  configuration: "Release"
```

---

## 📊 Implementation Checklist

### Pre-Implementation
- [ ] Review xccache implementation thoroughly
- [ ] Test current behavior with resource-containing package
- [ ] Set up test fixtures

### Core Implementation
- [ ] Create Swift resource accessor template
- [ ] Create ObjC resource accessor template
- [ ] Add resource detection to SPM::Package
- [ ] Add `override_resource_bundle_accessor` to FrameworkSlice
- [ ] Add `compile_resource_accessor` method
- [ ] Add `copy_resource_bundle` method
- [ ] Add `resolve_resource_symlinks` method
- [ ] Integrate into build pipeline

### Testing
- [ ] Unit test: resource bundle detection
- [ ] Unit test: accessor override
- [ ] Unit test: accessor compilation
- [ ] Unit test: bundle copying
- [ ] Unit test: symlink resolution
- [ ] Integration test: full build with resources
- [ ] Manual test: Bundle.module runtime access

### Documentation
- [ ] Update CLAUDE.md
- [ ] Add example config
- [ ] Add inline code comments
- [ ] Update README.md

---

## 🎯 Success Criteria

✅ **Implementation Complete When**:
1. SPM packages with resources build successfully
2. `Bundle.module` works at runtime in binary framework
3. All unit tests pass
4. Integration test with real resource package passes
5. No symlink issues in distributed framework
6. Documentation updated

---

## 📈 Estimated Timeline

| Phase | Duration | Cumulative |
|-------|----------|------------|
| Research & Setup | 2 hours | 2h |
| Template Creation | 1 hour | 3h |
| Resource Detection | 2 hours | 5h |
| Framework Override | 3 hours | 8h |
| Bundle Copying | 2 hours | 10h |
| Testing | 3 hours | 13h |
| Documentation | 1 hour | **14h total** |

**Estimated Total**: ~2 working days

---

## 🚨 Risk Mitigation

### Risk 1: Template Variables Mismatch
**Mitigation**: Test templates with real Package.swift early

### Risk 2: Clang vs Swift Detection
**Mitigation**: Parse Package.swift manifest to determine target type

### Risk 3: Symlink Resolution Failures
**Mitigation**: Add error handling and fallback to copying

### Risk 4: Resource Bundle Not Found at Runtime
**Mitigation**: Add extensive logging and clear error messages

---

## 📚 Reference Files

**Key xccache Files to Study**:
```
/tmp/xccache/lib/xccache/spm/xcframework/slice.rb:14-157
/tmp/xccache/tools/templates/resource_bundle_accessor.swift
/tmp/xccache/tools/templates/resource_bundle_accessor.m
```

**Key xcframework-cli Files to Modify**:
```
lib/xcframework_cli/spm/framework_slice.rb
lib/xcframework_cli/spm/package.rb
config/templates/resource_bundle_accessor.swift (new)
config/templates/resource_bundle_accessor.m (new)
spec/unit/spm/framework_slice_resource_spec.rb (new)
```

---

## 🔄 Next Steps

1. Review and approve this plan
2. Set up development environment
3. Start with Phase 1: Research
4. Implement iteratively, testing after each phase
5. Get feedback on core implementation before testing phase
6. Complete testing and documentation

**Ready to start implementation?** Begin with Phase 1: Research & Setup 🚀
