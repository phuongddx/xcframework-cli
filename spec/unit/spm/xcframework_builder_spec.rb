# frozen_string_literal: true

require 'spec_helper'
require 'xcframework_cli/spm/xcframework_builder'
require 'xcframework_cli/swift/sdk'

RSpec.describe XCFrameworkCLI::SPM::XCFrameworkBuilder do
  let(:target) { 'MyLibrary' }
  let(:sdk1) { instance_double(XCFrameworkCLI::Swift::SDK) }
  let(:sdk2) { instance_double(XCFrameworkCLI::Swift::SDK) }
  let(:sdks) { [sdk1, sdk2] }
  let(:package_dir) { '/path/to/package' }
  let(:output_path) { '/path/to/output/MyLibrary.xcframework' }

  let(:builder) do
    described_class.new(
      target: target,
      sdks: sdks,
      package_dir: package_dir,
      output_path: output_path,
      configuration: 'release',
      library_evolution: true
    )
  end

  before do
    allow(sdk1).to receive(:triple).and_return('arm64-apple-ios15.0')
    allow(sdk1).to receive(:to_s).and_return('iphoneos')
    allow(sdk1).to receive(:sdk_name).and_return(:iphoneos)
    allow(sdk2).to receive(:triple).and_return('x86_64-apple-ios15.0-simulator')
    allow(sdk2).to receive(:to_s).and_return('iphonesimulator')
    allow(sdk2).to receive(:sdk_name).and_return(:iphonesimulator)
  end

  describe '#initialize' do
    it 'initializes with required parameters' do
      expect(builder.target).to eq(target)
      expect(builder.sdks).to eq(sdks)
      expect(builder.package_dir).to eq(package_dir)
      expect(builder.output_path).to eq(output_path)
      expect(builder.configuration).to eq('release')
      expect(builder.library_evolution).to be true
    end
  end

  describe '#build' do
    let(:success_status) { instance_double(Process::Status, success?: true) }
    let(:slice_results) do
      [
        {
          success: true,
          framework_path: '/tmp/slice1/MyLibrary.framework',
          sdk: sdk1
        },
        {
          success: true,
          framework_path: '/tmp/slice2/MyLibrary.framework',
          sdk: sdk2
        }
      ]
    end

    before do
      allow(Dir).to receive(:mktmpdir).and_yield('/tmp/test')
      allow(builder).to receive(:build_framework_slices).and_return(slice_results)
      allow(FileUtils).to receive(:mkdir_p)
      allow(FileUtils).to receive(:rm_rf)
      allow(File).to receive(:exist?).and_return(false)
      allow(File).to receive(:dirname).and_return('/path/to/output')
      allow(Open3).to receive(:capture3).and_return(['', '', success_status])
    end

    context 'when all slices succeed' do
      it 'builds framework slices' do
        expect(builder).to receive(:build_framework_slices).and_return(slice_results)
        builder.build
      end

      it 'creates xcframework' do
        expect(Open3).to receive(:capture3).with(/xcodebuild/, any_args)
        builder.build
      end

      it 'returns success result' do
        result = builder.build

        expect(result[:success]).to be true
        expect(result[:xcframework_path]).to eq(output_path)
        expect(result[:slices]).to eq(slice_results)
      end
    end

    context 'when all slices fail' do
      let(:failed_slice_results) do
        [
          {
            success: false,
            framework_path: nil,
            error: 'Build failed',
            sdk: sdk1
          },
          {
            success: false,
            framework_path: nil,
            error: 'Build failed',
            sdk: sdk2
          }
        ]
      end

      before do
        allow(builder).to receive(:build_framework_slices).and_return(failed_slice_results)
      end

      it 'returns failure result' do
        result = builder.build

        expect(result[:success]).to be false
        expect(result[:xcframework_path]).to be_nil
        expect(result[:errors]).to include('All framework slice builds failed')
      end
    end

    context 'when some slices succeed' do
      let(:mixed_slice_results) do
        [
          {
            success: true,
            framework_path: '/tmp/slice1/MyLibrary.framework',
            sdk: sdk1
          },
          {
            success: false,
            framework_path: nil,
            error: 'Build failed',
            sdk: sdk2
          }
        ]
      end

      before do
        allow(builder).to receive(:build_framework_slices).and_return(mixed_slice_results)
      end

      it 'continues with successful slices' do
        expect(Open3).to receive(:capture3).with(/xcodebuild/, any_args)
        builder.build
      end

      it 'returns success if xcframework creation succeeds' do
        result = builder.build

        expect(result[:success]).to be true
        expect(result[:slices].length).to eq(2)
      end
    end

    context 'when xcframework creation fails' do
      let(:failure_status) { instance_double(Process::Status, success?: false) }

      before do
        allow(Open3).to receive(:capture3).and_return(['', 'xcodebuild error', failure_status])
      end

      it 'returns failure result' do
        result = builder.build

        expect(result[:success]).to be false
        expect(result[:errors]).to include(/xcodebuild -create-xcframework failed/)
      end
    end

    context 'when exception occurs' do
      before do
        allow(builder).to receive(:build_framework_slices).and_raise(StandardError, 'Unexpected error')
      end

      it 'returns failure result with error message' do
        result = builder.build

        expect(result[:success]).to be false
        expect(result[:errors]).to include('Unexpected error')
      end
    end
  end

  describe '#build_framework_slices' do
    let(:slice_double) { instance_double(XCFrameworkCLI::SPM::FrameworkSlice) }
    let(:tmpdir) { '/tmp/test' }

    before do
      allow(FileUtils).to receive(:mkdir_p)
      allow(XCFrameworkCLI::SPM::FrameworkSlice).to receive(:new).and_return(slice_double)
      allow(slice_double).to receive(:build).and_return(success: true, framework_path: '/tmp/MyLibrary.framework')
    end

    it 'builds slice for each SDK' do
      expect(XCFrameworkCLI::SPM::FrameworkSlice).to receive(:new).twice
      builder.send(:build_framework_slices, tmpdir)
    end

    it 'returns slice results' do
      results = builder.send(:build_framework_slices, tmpdir)

      expect(results.length).to eq(2)
      expect(results.all? { |r| r[:success] }).to be true
    end
  end

  describe '#build_xcframework_command' do
    let(:slice_results) do
      [
        { framework_path: '/path/to/slice1.framework' },
        { framework_path: '/path/to/slice2.framework' }
      ]
    end

    it 'includes xcodebuild -create-xcframework' do
      cmd = builder.send(:build_xcframework_command, slice_results)
      expect(cmd).to include('xcodebuild', '-create-xcframework')
    end

    it 'includes framework paths' do
      cmd = builder.send(:build_xcframework_command, slice_results)
      expect(cmd).to include('-framework', '/path/to/slice1.framework')
      expect(cmd).to include('-framework', '/path/to/slice2.framework')
    end

    it 'includes output path' do
      cmd = builder.send(:build_xcframework_command, slice_results)
      expect(cmd).to include('-output', output_path)
    end

    context 'without library evolution' do
      let(:builder_no_evolution) do
        described_class.new(
          target: target,
          sdks: sdks,
          package_dir: package_dir,
          output_path: output_path,
          library_evolution: false
        )
      end

      it 'includes -allow-internal-distribution flag' do
        cmd = builder_no_evolution.send(:build_xcframework_command, slice_results)
        expect(cmd).to include('-allow-internal-distribution')
      end
    end

    context 'with library evolution' do
      it 'does not include -allow-internal-distribution flag' do
        cmd = builder.send(:build_xcframework_command, slice_results)
        expect(cmd).not_to include('-allow-internal-distribution')
      end
    end
  end

  describe '.build_for_platforms' do
    before do
      allow(XCFrameworkCLI::Swift::SDK).to receive(:sdks_for_platform)
        .with('ios', version: '15.0').and_return([sdk1])
      allow(XCFrameworkCLI::Swift::SDK).to receive(:sdks_for_platform)
        .with('ios-simulator', version: '15.0').and_return([sdk2])

      allow_any_instance_of(described_class).to receive(:build).and_return(
        success: true,
        xcframework_path: output_path
      )
    end

    it 'builds xcframework for platforms' do
      result = described_class.build_for_platforms(
        target: target,
        platforms: %w[ios ios-simulator],
        package_dir: package_dir,
        output_dir: '/path/to/output',
        version: '15.0'
      )

      expect(result[:success]).to be true
    end

    it 'converts platforms to SDKs' do
      expect(XCFrameworkCLI::Swift::SDK).to receive(:sdks_for_platform).with('ios', version: '15.0')
      expect(XCFrameworkCLI::Swift::SDK).to receive(:sdks_for_platform).with('ios-simulator', version: '15.0')

      described_class.build_for_platforms(
        target: target,
        platforms: %w[ios ios-simulator],
        package_dir: package_dir,
        output_dir: '/path/to/output',
        version: '15.0'
      )
    end
  end

  describe '#module_name' do
    it 'sanitizes target name' do
      builder_with_special = described_class.new(
        target: 'My-Library.Framework',
        sdks: sdks,
        package_dir: package_dir,
        output_path: output_path
      )

      expect(builder_with_special.send(:module_name)).to eq('My_Library_Framework')
    end
  end
end
