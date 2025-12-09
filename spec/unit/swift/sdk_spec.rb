# frozen_string_literal: true

require 'spec_helper'
require 'xcframework_cli/swift/sdk'

RSpec.describe XCFrameworkCLI::Swift::SDK do
  describe '#initialize' do
    it 'creates SDK with default architecture' do
      sdk = described_class.new(:iphoneos)
      expect(sdk.name).to eq(:iphoneos)
      expect(sdk.architecture).to eq('arm64')
      expect(sdk.vendor).to eq('apple')
      expect(sdk.platform).to eq(:ios)
    end

    it 'creates SDK with custom architecture' do
      sdk = described_class.new(:iphonesimulator, architecture: 'x86_64')
      expect(sdk.architecture).to eq('x86_64')
    end

    it 'creates SDK with version' do
      sdk = described_class.new(:iphoneos, version: '15.0')
      expect(sdk.version).to eq('15.0')
    end

    it 'raises error for unknown SDK' do
      expect do
        described_class.new(:unknown_sdk)
      end.to raise_error(XCFrameworkCLI::ValidationError, /Unknown SDK/)
    end
  end

  describe '#triple' do
    let(:sdk) { described_class.new(:iphoneos, architecture: 'arm64', version: '15.0') }

    it 'generates triple without vendor or version' do
      triple = sdk.triple(with_vendor: false, with_version: false)
      expect(triple).to eq('arm64-ios')
    end

    it 'generates triple with vendor' do
      triple = sdk.triple(with_vendor: true, with_version: false)
      expect(triple).to eq('arm64-apple-ios')
    end

    it 'generates triple with version' do
      triple = sdk.triple(with_vendor: true, with_version: true)
      expect(triple).to eq('arm64-apple-ios15.0')
    end

    context 'for simulator' do
      let(:sim_sdk) { described_class.new(:iphonesimulator, architecture: 'x86_64', version: '15.0') }

      it 'includes simulator suffix' do
        triple = sim_sdk.triple(with_vendor: true, with_version: true)
        expect(triple).to eq('x86_64-apple-ios15.0-simulator')
      end
    end
  end

  describe '#sdk_name' do
    it 'returns iphoneos for iphoneos' do
      sdk = described_class.new(:iphoneos)
      expect(sdk.sdk_name).to eq(:iphoneos)
    end

    it 'returns iphonesimulator for iphonesimulator' do
      sdk = described_class.new(:iphonesimulator)
      expect(sdk.sdk_name).to eq(:iphonesimulator)
    end

    it 'returns macosx for macos' do
      sdk = described_class.new(:macos)
      expect(sdk.sdk_name).to eq(:macosx)
    end
  end

  describe '#sdk_path' do
    let(:sdk) { described_class.new(:iphoneos) }
    let(:success_status) { instance_double(Process::Status, success?: true) }
    let(:failure_status) { instance_double(Process::Status, success?: false) }

    it 'returns SDK path from xcrun' do
      expect(Open3).to receive(:capture3).with('xcrun', '--sdk', 'iphoneos', '--show-sdk-path')
                                         .and_return(["/path/to/sdk\n", '', success_status])

      expect(sdk.sdk_path).to eq('/path/to/sdk')
    end

    it 'raises error if xcrun fails' do
      expect(Open3).to receive(:capture3).with('xcrun', '--sdk', 'iphoneos', '--show-sdk-path')
                                         .and_return(['', 'error message', failure_status])

      expect { sdk.sdk_path }.to raise_error(XCFrameworkCLI::Error, /Failed to get SDK path/)
    end
  end

  describe '#swiftc_args' do
    let(:sdk) { described_class.new(:iphoneos) }

    before do
      allow(sdk).to receive(:sdk_path).and_return('/path/to/iPhoneOS.sdk')
      allow(sdk).to receive(:sdk_platform_developer_path).and_return('/path/to/iPhoneOS.platform/Developer')
    end

    it 'returns framework and include paths' do
      args = sdk.swiftc_args
      expect(args).to include('-F/path/to/iPhoneOS.platform/Developer/Library/Frameworks')
      expect(args).to include('-I/path/to/iPhoneOS.platform/Developer/usr/lib')
    end
  end

  describe '#simulator?' do
    it 'returns true for simulator SDKs' do
      expect(described_class.new(:iphonesimulator).simulator?).to be true
      expect(described_class.new(:watchsimulator).simulator?).to be true
      expect(described_class.new(:appletvsimulator).simulator?).to be true
      expect(described_class.new(:xrsimulator).simulator?).to be true
    end

    it 'returns false for device SDKs' do
      expect(described_class.new(:iphoneos).simulator?).to be false
      expect(described_class.new(:macos).simulator?).to be false
      expect(described_class.new(:watchos).simulator?).to be false
      expect(described_class.new(:appletvos).simulator?).to be false
    end
  end

  describe '#to_s' do
    it 'returns SDK name as string' do
      sdk = described_class.new(:iphoneos)
      expect(sdk.to_s).to eq('iphoneos')
    end
  end

  describe '.sdks_for_platform' do
    it 'returns iOS device SDK' do
      sdks = described_class.sdks_for_platform('ios', version: '15.0')
      expect(sdks.length).to eq(1)
      expect(sdks[0].name).to eq(:iphoneos)
      expect(sdks[0].architecture).to eq('arm64')
      expect(sdks[0].version).to eq('15.0')
    end

    it 'returns iOS simulator SDKs' do
      sdks = described_class.sdks_for_platform('ios-simulator', version: '15.0')
      expect(sdks.length).to eq(2)
      expect(sdks.map(&:architecture)).to contain_exactly('arm64', 'x86_64')
      expect(sdks.all? { |s| s.name == :iphonesimulator }).to be true
    end

    it 'returns macOS SDKs' do
      sdks = described_class.sdks_for_platform('macos', version: '12.0')
      expect(sdks.length).to eq(2)
      expect(sdks.map(&:architecture)).to contain_exactly('arm64', 'x86_64')
      expect(sdks.all? { |s| s.name == :macos }).to be true
    end

    it 'returns tvOS device SDK' do
      sdks = described_class.sdks_for_platform('tvos')
      expect(sdks.length).to eq(1)
      expect(sdks[0].name).to eq(:appletvos)
    end

    it 'returns tvOS simulator SDKs' do
      sdks = described_class.sdks_for_platform('tvos-simulator')
      expect(sdks.length).to eq(2)
      expect(sdks.map(&:architecture)).to contain_exactly('arm64', 'x86_64')
    end

    it 'returns watchOS device SDKs' do
      sdks = described_class.sdks_for_platform('watchos')
      expect(sdks.length).to eq(2)
      expect(sdks.map(&:architecture)).to contain_exactly('arm64_32', 'armv7k')
    end

    it 'returns visionOS device SDK' do
      sdks = described_class.sdks_for_platform('visionos')
      expect(sdks.length).to eq(1)
      expect(sdks[0].name).to eq(:xros)
    end

    it 'returns Catalyst SDKs' do
      sdks = described_class.sdks_for_platform('catalyst')
      expect(sdks.length).to eq(2)
      expect(sdks.all? { |s| s.name == :macos }).to be true
    end

    it 'raises error for unknown platform' do
      expect do
        described_class.sdks_for_platform('unknown')
      end.to raise_error(XCFrameworkCLI::ValidationError, /Unknown platform identifier/)
    end
  end

  describe 'platform mapping' do
    it 'maps iphoneos to ios platform' do
      sdk = described_class.new(:iphoneos)
      expect(sdk.platform).to eq(:ios)
    end

    it 'maps iphonesimulator to ios platform' do
      sdk = described_class.new(:iphonesimulator)
      expect(sdk.platform).to eq(:ios)
    end

    it 'maps xros to visionos platform' do
      sdk = described_class.new(:xros)
      expect(sdk.platform).to eq(:visionos)
    end

    it 'maps macos to macos platform' do
      sdk = described_class.new(:macos)
      expect(sdk.platform).to eq(:macos)
    end
  end
end
