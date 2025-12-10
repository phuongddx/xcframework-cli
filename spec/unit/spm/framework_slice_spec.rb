# frozen_string_literal: true

require 'spec_helper'
require 'xcframework_cli/spm/framework_slice'
require 'xcframework_cli/swift/sdk'
require 'tmpdir'

RSpec.describe XCFrameworkCLI::SPM::FrameworkSlice do
  let(:target) { 'MyLibrary' }
  let(:sdk) { instance_double(XCFrameworkCLI::Swift::SDK) }
  let(:package_dir) { '/path/to/package' }
  let(:output_path) { '/path/to/output/MyLibrary.framework' }
  let(:tmpdir) { Dir.mktmpdir }

  let(:slice) do
    described_class.new(
      target: target,
      sdk: sdk,
      package_dir: package_dir,
      output_path: output_path,
      configuration: 'release',
      library_evolution: true,
      tmpdir: tmpdir
    )
  end

  before do
    allow(sdk).to receive(:triple).and_return('arm64-apple-ios15.0')
    allow(sdk).to receive(:name).and_return(:iphoneos)
    allow(sdk).to receive(:version).and_return('15.0')
    allow(sdk).to receive(:to_s).and_return('iphoneos')
  end

  after do
    FileUtils.rm_rf(tmpdir) if File.exist?(tmpdir)
  end

  describe '#initialize' do
    it 'initializes with required parameters' do
      expect(slice.target).to eq(target)
      expect(slice.sdk).to eq(sdk)
      expect(slice.package_dir).to eq(package_dir)
      expect(slice.output_path).to eq(output_path)
      expect(slice.configuration).to eq('release')
      expect(slice.library_evolution).to be true
    end

    it 'creates temporary directory if not provided' do
      slice_without_tmpdir = described_class.new(
        target: target,
        sdk: sdk,
        package_dir: package_dir,
        output_path: output_path
      )

      expect(slice_without_tmpdir.tmpdir).to be_a(String)
      expect(slice_without_tmpdir.tmpdir).to include('xcframework-slice')
    end
  end

  describe '#build' do
    let(:builder_double) { instance_double(XCFrameworkCLI::Swift::Builder) }
    let(:success_status) { instance_double(Process::Status, success?: true) }
    let(:build_result) do
      {
        success: true,
        build_dir: '/path/to/.build/arm64-apple-ios15.0/release',
        products_dir: '/path/to/.build/arm64-apple-ios15.0/release'
      }
    end

    before do
      allow(XCFrameworkCLI::Swift::Builder).to receive(:new).and_return(builder_double)
      allow(builder_double).to receive(:build).and_return(build_result)
    end

    context 'when swift build succeeds' do
      before do
        # Mock filesystem operations
        allow(FileUtils).to receive(:mkdir_p)
        allow(FileUtils).to receive(:cp)
        allow(FileUtils).to receive(:chmod)
        allow(File).to receive(:write)
        allow(File).to receive(:directory?).and_return(true)
        allow(File).to receive(:exist?).and_return(false)
        allow(File).to receive(:dirname).and_return('/path/to/output')
        allow(Dir).to receive(:glob).and_return([])

        # Disable resource bundle detection for basic build tests
        allow(slice).to receive(:has_resource_bundle?).and_return(false)

        # Mock libtool execution
        allow(Open3).to receive(:capture3).with(/libtool/, any_args).and_return(['', '', success_status])

        # Mock object files
        allow(slice).to receive(:find_object_files).and_return(['/path/to/file1.o', '/path/to/file2.o'])

        # Mock template rendering
        allow(XCFrameworkCLI::Utils::Template).to receive(:render).and_return('')
      end

      it 'executes swift build' do
        expect(XCFrameworkCLI::Swift::Builder).to receive(:new).with(
          package_dir: package_dir,
          target: target,
          sdk: sdk,
          configuration: 'release',
          library_evolution: true
        )

        slice.build
      end

      it 'returns success result' do
        result = slice.build

        expect(result[:success]).to be true
        expect(result[:framework_path]).to eq(output_path)
        expect(result[:sdk]).to eq(sdk)
      end

      it 'creates framework structure' do
        expect(slice).to receive(:create_framework_structure)
        slice.build
      end
    end

    context 'when target has resource bundle' do
      let(:package_manifest) do
        { name: 'MyPackage' }.to_json
      end

      before do
        # SDK mocks for resource bundle compilation
        allow(sdk).to receive(:sdk_path).and_return('/path/to/sdk')
        allow(sdk).to receive(:triple).with(with_version: true).and_return('arm64-apple-ios15.0')

        # Core filesystem mocks
        allow(FileUtils).to receive(:mkdir_p)
        allow(FileUtils).to receive(:cp)
        allow(FileUtils).to receive(:cp_r)
        allow(FileUtils).to receive(:chmod)
        allow(File).to receive(:write)
        allow(File).to receive(:dirname).and_return('/path/to/output')
        allow(Dir).to receive(:glob).and_return([])
        allow(XCFrameworkCLI::Utils::Template).to receive(:render).and_return('')

        # Mock object files
        allow(slice).to receive(:find_object_files)
          .and_return(['/path/to/file1.o', '/path/to/file2.o'])

        # Mock swift package dump-package
        allow(Open3).to receive(:capture3)
          .with('swift', 'package', 'dump-package', '--package-path', package_dir)
          .and_return([package_manifest, '', success_status])

        # Mock libtool
        allow(Open3).to receive(:capture3).with(/libtool/, any_args)
          .and_return(['', '', success_status])

        # Mock resource accessor compilation
        allow(Open3).to receive(:capture3)
          .with('xcrun', 'swiftc', any_args)
          .and_return(['', '', success_status])

        # Resource bundle exists
        bundle_path = '/path/to/.build/arm64-apple-ios15.0/release/MyPackage_MyLibrary.bundle'
        allow(File).to receive(:directory?).and_call_original
        allow(File).to receive(:directory?).with(bundle_path).and_return(true)

        # No symlinks in bundle
        allow(File).to receive(:exist?).and_return(true)
        allow(File).to receive(:symlink?).and_return(false)
      end

      it 'compiles resource bundle accessor' do
        expect(slice).to receive(:override_resource_bundle_accessor).and_call_original
        slice.build
      end

      it 'copies resource bundle to framework' do
        expect(slice).to receive(:copy_resource_bundle).and_call_original
        slice.build
      end

      it 'checks for resource bundle' do
        expect(slice).to receive(:has_resource_bundle?).at_least(:once).and_call_original
        slice.build
      end
    end

    context 'when swift build fails' do
      let(:build_result) do
        {
          success: false,
          error: 'Build failed'
        }
      end

      it 'returns failure result' do
        result = slice.build

        expect(result[:success]).to be false
        expect(result[:framework_path]).to be_nil
        expect(result[:error]).to include('Swift build failed')
      end
    end

    context 'when framework creation fails' do
      before do
        allow(slice).to receive(:create_framework_structure).and_raise(StandardError, 'Creation failed')
      end

      it 'returns failure result with error' do
        result = slice.build

        expect(result[:success]).to be false
        expect(result[:error]).to eq('Creation failed')
      end
    end
  end

  describe '#module_name' do
    it 'returns sanitized module name' do
      slice_with_special = described_class.new(
        target: 'My-Library.Framework',
        sdk: sdk,
        package_dir: package_dir,
        output_path: output_path
      )

      expect(slice_with_special.send(:module_name)).to eq('My_Library_Framework')
    end

    it 'keeps alphanumeric and underscores' do
      expect(slice.send(:module_name)).to eq('MyLibrary')
    end
  end

  describe '#platform_name' do
    it 'returns iPhoneOS for iphoneos SDK' do
      allow(sdk).to receive(:name).and_return(:iphoneos)
      expect(slice.send(:platform_name)).to eq('iPhoneOS')
    end

    it 'returns iPhoneSimulator for iphonesimulator SDK' do
      allow(sdk).to receive(:name).and_return(:iphonesimulator)
      expect(slice.send(:platform_name)).to eq('iPhoneSimulator')
    end

    it 'returns MacOSX for macos SDK' do
      allow(sdk).to receive(:name).and_return(:macos)
      expect(slice.send(:platform_name)).to eq('MacOSX')
    end

    it 'returns AppleTVOS for appletvos SDK' do
      allow(sdk).to receive(:name).and_return(:appletvos)
      expect(slice.send(:platform_name)).to eq('AppleTVOS')
    end
  end

  describe '#min_os_version' do
    it 'returns SDK version' do
      allow(sdk).to receive(:version).and_return('15.0')
      expect(slice.send(:min_os_version)).to eq('15.0')
    end

    it 'returns 1.0 if SDK version is nil' do
      allow(sdk).to receive(:version).and_return(nil)
      expect(slice.send(:min_os_version)).to eq('1.0')
    end
  end

  describe '#find_object_files' do
    let(:products_dir) { '/path/to/products' }
    let(:build_subdir) { '/path/to/products/MyLibrary.build' }

    before do
      allow(slice).to receive(:products_dir).and_return(products_dir)
    end

    it 'finds .o files in build directory' do
      allow(File).to receive(:directory?).with(build_subdir).and_return(true)
      allow(Dir).to receive(:glob).with(File.join(build_subdir, '**', '*.o'))
                                  .and_return(['/path/file1.o', '/path/file2.o'])
      allow(File).to receive(:expand_path).and_call_original

      files = slice.send(:find_object_files)
      expect(files.length).to eq(2)
    end

    it 'raises error if build directory not found' do
      allow(File).to receive(:directory?).with(build_subdir).and_return(false)

      expect do
        slice.send(:find_object_files)
      end.to raise_error(XCFrameworkCLI::Error, /Build directory not found/)
    end
  end

  describe '#package_name' do
    let(:success_status) { instance_double(Process::Status, success?: true) }
    let(:failure_status) { instance_double(Process::Status, success?: false) }

    it 'extracts package name from swift package dump-package' do
      manifest = { name: 'MyAwesomePackage' }.to_json
      allow(Open3).to receive(:capture3)
        .with('swift', 'package', 'dump-package', '--package-path', package_dir)
        .and_return([manifest, '', success_status])

      expect(slice.send(:package_name)).to eq('MyAwesomePackage')
    end

    it 'falls back to directory name on failure' do
      allow(Open3).to receive(:capture3)
        .with('swift', 'package', 'dump-package', '--package-path', package_dir)
        .and_return(['', 'error', failure_status])

      expect(slice.send(:package_name)).to eq('package')
    end

    it 'caches result' do
      manifest = { name: 'CachedPackage' }.to_json
      expect(Open3).to receive(:capture3).once
        .and_return([manifest, '', success_status])

      slice.send(:package_name)
      slice.send(:package_name)
    end
  end

  describe '#create_framework_binary' do
    let(:success_status) { instance_double(Process::Status, success?: true) }

    before do
      allow(slice).to receive(:find_object_files).and_return(['/path/file1.o'])
      allow(slice).to receive(:products_dir).and_return('/build/products')
      allow(File).to receive(:write)
      allow(FileUtils).to receive(:chmod)
    end

    it 'creates binary using libtool' do
      expect(Open3).to receive(:capture3).with(
        'libtool', '-static', '-o', anything, '-filelist', anything
      ).and_return(['', '', success_status])

      slice.send(:create_framework_binary)
    end

    it 'raises error when no object files found' do
      allow(slice).to receive(:find_object_files).and_return([])

      expect do
        slice.send(:create_framework_binary)
      end.to raise_error(XCFrameworkCLI::Error, /No object files found/)
    end

    it 'raises error when libtool fails' do
      failure_status = instance_double(Process::Status, success?: false)
      allow(Open3).to receive(:capture3).and_return(['', 'libtool error', failure_status])

      expect do
        slice.send(:create_framework_binary)
      end.to raise_error(XCFrameworkCLI::Error, /libtool failed/)
    end

    it 'makes binary executable' do
      allow(Open3).to receive(:capture3).and_return(['', '', success_status])

      expect(FileUtils).to receive(:chmod).with('+x', anything)
      slice.send(:create_framework_binary)
    end
  end

  describe '#create_headers' do
    before do
      allow(FileUtils).to receive(:mkdir_p)
      allow(FileUtils).to receive(:cp)
      allow(File).to receive(:write)
      allow(slice).to receive(:products_dir).and_return('/build/products')
    end

    it 'creates Headers directory' do
      allow(Dir).to receive(:glob).and_return([])

      expect(FileUtils).to receive(:mkdir_p).with(%r{Headers$})
      slice.send(:create_headers)
    end

    it 'copies Swift-generated headers' do
      swift_header = '/build/products/MyLibrary.build/MyLibrary-Swift.h'
      allow(Dir).to receive(:glob).and_return([swift_header])

      expect(FileUtils).to receive(:cp).with(swift_header, anything)
      slice.send(:create_headers)
    end

    it 'creates umbrella header' do
      swift_header = '/build/products/MyLibrary.build/MyLibrary-Swift.h'
      allow(Dir).to receive(:glob).and_return([swift_header])

      expect(File).to receive(:write).with(
        %r{MyLibrary-umbrella\.h$},
        /#import <MyLibrary\/MyLibrary-Swift\.h>/
      )

      slice.send(:create_headers)
    end
  end

  describe '#create_info_plist' do
    it 'renders Info.plist template' do
      expect(XCFrameworkCLI::Utils::Template).to receive(:render).with(
        'framework.info.plist',
        hash_including(
          MODULE_NAME: 'MyLibrary',
          PLATFORM: 'iPhoneOS',
          MIN_OS_VERSION: '15.0'
        ),
        save_to: anything
      )

      slice.send(:create_info_plist)
    end
  end

  describe '#copy_swiftmodules' do
    let(:modules_dir) { '/path/to/Modules' }

    before do
      allow(FileUtils).to receive(:mkdir_p)
      allow(FileUtils).to receive(:cp)
      allow(slice).to receive(:products_dir).and_return('/build/products')
    end

    it 'creates swiftmodule directory' do
      allow(Dir).to receive(:glob).and_return([])

      expect(FileUtils).to receive(:mkdir_p).with(%r{MyLibrary\.swiftmodule$})
      slice.send(:copy_swiftmodules, modules_dir)
    end

    it 'copies module files with triple-based names' do
      module_file = '/build/products/Modules/MyLibrary.swiftmodule'
      allow(Dir).to receive(:glob).and_return([module_file])

      expect(FileUtils).to receive(:cp).with(
        module_file,
        %r{arm64-apple-ios15\.0\.swiftmodule$}
      )

      slice.send(:copy_swiftmodules, modules_dir)
    end

    it 'logs warning when no module files found' do
      allow(Dir).to receive(:glob).and_return([])

      expect(XCFrameworkCLI::Utils::Logger).to receive(:warning)
        .with(/No Swift module files found/)

      slice.send(:copy_swiftmodules, modules_dir)
    end
  end

  describe '#create_modules' do
    before do
      allow(FileUtils).to receive(:mkdir_p)
      allow(slice).to receive(:create_modulemap)
      allow(slice).to receive(:copy_swiftmodules)
    end

    it 'creates Modules directory' do
      expect(FileUtils).to receive(:mkdir_p).with(%r{Modules$})
      slice.send(:create_modules)
    end

    it 'creates modulemap' do
      expect(slice).to receive(:create_modulemap).with(anything)
      slice.send(:create_modules)
    end

    it 'copies Swift modules' do
      expect(slice).to receive(:copy_swiftmodules).with(anything)
      slice.send(:create_modules)
    end
  end

  describe '#create_modulemap' do
    let(:modules_dir) { '/path/to/Modules' }

    it 'renders modulemap template' do
      expect(XCFrameworkCLI::Utils::Template).to receive(:render).with(
        'framework.modulemap',
        { MODULE_NAME: 'MyLibrary' },
        save_to: %r{module\.modulemap$}
      )

      slice.send(:create_modulemap, modules_dir)
    end
  end
end
