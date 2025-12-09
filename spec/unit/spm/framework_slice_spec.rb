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
end
