# frozen_string_literal: true

require 'spec_helper'
require 'xcframework_cli/swift/sdk'
require 'xcframework_cli/swift/builder'

RSpec.describe XCFrameworkCLI::Swift::Builder do
  let(:package_dir) { '/path/to/package' }
  let(:target) { 'MyLibrary' }
  let(:sdk) { instance_double(XCFrameworkCLI::Swift::SDK) }
  let(:builder) do
    described_class.new(
      package_dir: package_dir,
      target: target,
      sdk: sdk,
      configuration: 'release',
      library_evolution: true
    )
  end

  before do
    allow(sdk).to receive(:triple).with(with_version: true).and_return('arm64-apple-ios15.0')
    allow(sdk).to receive(:triple).with(no_args).and_return('arm64-apple-ios')
    allow(sdk).to receive(:sdk_path).and_return('/path/to/iPhoneOS.sdk')
    allow(sdk).to receive(:swiftc_args).and_return(['-F/path/to/Frameworks'])
    allow(File).to receive(:exist?).with(File.join(package_dir, 'Package.swift')).and_return(true)
  end

  describe '#initialize' do
    it 'initializes with required parameters' do
      expect(builder.package_dir).to eq(package_dir)
      expect(builder.target).to eq(target)
      expect(builder.sdk).to eq(sdk)
      expect(builder.configuration).to eq('release')
      expect(builder.library_evolution).to be true
    end

    it 'accepts debug configuration' do
      debug_builder = described_class.new(
        package_dir: package_dir,
        target: target,
        sdk: sdk,
        configuration: 'debug'
      )
      expect(debug_builder.configuration).to eq('debug')
    end

    it 'raises error for invalid configuration' do
      expect do
        described_class.new(
          package_dir: package_dir,
          target: target,
          sdk: sdk,
          configuration: 'invalid'
        )
      end.to raise_error(XCFrameworkCLI::ValidationError, /Invalid configuration/)
    end

    it 'raises error if Package.swift not found' do
      allow(File).to receive(:exist?).with(File.join(package_dir, 'Package.swift')).and_return(false)

      expect do
        described_class.new(
          package_dir: package_dir,
          target: target,
          sdk: sdk
        )
      end.to raise_error(XCFrameworkCLI::ValidationError, /No Package.swift found/)
    end
  end

  describe '#build' do
    let(:success_output) { 'Build complete!' }
    let(:success_status) { instance_double(Process::Status, success?: true) }
    let(:failure_status) { instance_double(Process::Status, success?: false) }

    before do
      allow(builder).to receive(:execute_command).and_return({ output: success_output, status: success_status })
    end

    it 'executes swift build command' do
      expected_cmd = [
        'swift', 'build',
        '--package-path', package_dir,
        '--target', target,
        '--configuration', 'release',
        '--triple', 'arm64-apple-ios15.0',
        '--sdk', '/path/to/iPhoneOS.sdk',
        '-Xswiftc', '-F/path/to/Frameworks',
        '-Xswiftc', '-enable-library-evolution',
        '-Xswiftc', '-emit-module-interface',
        '-Xswiftc', '-no-verify-emitted-module-interface'
      ]

      expect(builder).to receive(:execute_command).with(expected_cmd)
        .and_return({ output: success_output, status: success_status })

      result = builder.build
      expect(result[:success]).to be true
      expect(result[:build_dir]).to include('.build/arm64-apple-ios/release')
    end

    it 'returns success result on successful build' do
      result = builder.build

      expect(result[:success]).to be true
      expect(result[:build_dir]).to eq(File.join(package_dir, '.build', 'arm64-apple-ios', 'release'))
      expect(result[:products_dir]).to eq(result[:build_dir])
      expect(result[:triple]).to eq('arm64-apple-ios')
      expect(result[:output]).to eq(success_output)
    end

    it 'returns failure result on build error' do
      error_output = 'Build failed!'
      allow(builder).to receive(:execute_command).and_return({ output: error_output, status: failure_status })

      result = builder.build

      expect(result[:success]).to be false
      expect(result[:build_dir]).to be_nil
      expect(result[:error]).to eq(error_output)
    end

    it 'handles exceptions during build' do
      allow(builder).to receive(:execute_command).and_raise(StandardError, 'Command failed')

      result = builder.build

      expect(result[:success]).to be false
      expect(result[:error]).to eq('Command failed')
    end

    context 'without library evolution' do
      let(:builder_no_evolution) do
        described_class.new(
          package_dir: package_dir,
          target: target,
          sdk: sdk,
          library_evolution: false
        )
      end

      it 'omits library evolution flags' do
        expected_cmd = [
          'swift', 'build',
          '--package-path', package_dir,
          '--target', target,
          '--configuration', 'release',
          '--triple', 'arm64-apple-ios15.0',
          '--sdk', '/path/to/iPhoneOS.sdk',
          '-Xswiftc', '-F/path/to/Frameworks'
        ]

        expect(builder_no_evolution).to receive(:execute_command).with(expected_cmd)
          .and_return({ output: success_output, status: success_status })

        builder_no_evolution.build
      end
    end
  end

  describe '#products_dir' do
    it 'returns products directory path' do
      expected_path = File.join(package_dir, '.build', 'arm64-apple-ios', 'release')
      expect(builder.products_dir).to eq(expected_path)
    end
  end

  describe '#object_files_dir' do
    it 'returns object files directory for target' do
      expected_path = File.join(package_dir, '.build', 'arm64-apple-ios', 'release', 'MyLibrary.build')
      expect(builder.object_files_dir).to eq(expected_path)
    end

    it 'accepts custom module name' do
      expected_path = File.join(package_dir, '.build', 'arm64-apple-ios', 'release', 'CustomModule.build')
      expect(builder.object_files_dir(module_name: 'CustomModule')).to eq(expected_path)
    end
  end

  describe '.build_for_sdks' do
    let(:sdk1) { instance_double(XCFrameworkCLI::Swift::SDK) }
    let(:sdk2) { instance_double(XCFrameworkCLI::Swift::SDK) }
    let(:sdks) { [sdk1, sdk2] }

    before do
      [sdk1, sdk2].each do |s|
        allow(s).to receive(:triple).with(with_version: true).and_return('arm64-apple-ios15.0')
        allow(s).to receive(:triple).with(no_args).and_return('arm64-apple-ios')
        allow(s).to receive(:sdk_path).and_return('/path/to/sdk')
        allow(s).to receive(:swiftc_args).and_return([])
      end
    end

    it 'builds for multiple SDKs' do
      success_status = instance_double(Process::Status, success?: true)
      allow_any_instance_of(described_class).to receive(:execute_command)
        .and_return({ output: 'Success', status: success_status })

      results = described_class.build_for_sdks(
        package_dir: package_dir,
        target: target,
        sdks: sdks,
        configuration: 'release'
      )

      expect(results.length).to eq(2)
      expect(results[0][:sdk]).to eq(sdk1)
      expect(results[1][:sdk]).to eq(sdk2)
      expect(results.all? { |r| r[:success] }).to be true
    end
  end

  describe '.package_platforms' do
    let(:package_json) do
      {
        platforms: [
          { platformName: 'ios', version: '15.0' },
          { platformName: 'macos', version: '12.0' }
        ]
      }.to_json
    end
    let(:success_status) { instance_double(Process::Status, success?: true) }
    let(:failure_status) { instance_double(Process::Status, success?: false) }

    it 'parses platforms from Package.swift' do
      expect(Open3).to receive(:capture3).with('swift', 'package', 'dump-package', '--package-path', package_dir)
                                         .and_return([package_json, '', success_status])

      platforms = described_class.package_platforms(package_dir)

      expect(platforms).to eq('ios' => '15.0', 'macos' => '12.0')
    end

    it 'returns empty hash on parse error' do
      expect(Open3).to receive(:capture3).with('swift', 'package', 'dump-package', '--package-path', package_dir)
                                         .and_return(['invalid json', '', success_status])

      platforms = described_class.package_platforms(package_dir)

      expect(platforms).to eq({})
    end

    it 'returns empty hash when swift package fails' do
      expect(Open3).to receive(:capture3).with('swift', 'package', 'dump-package', '--package-path', package_dir)
                                         .and_return(['', 'error', failure_status])

      platforms = described_class.package_platforms(package_dir)

      expect(platforms).to eq({})
    end
  end
end
