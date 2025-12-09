# frozen_string_literal: true

require 'spec_helper'
require 'xcframework_cli/builder/orchestrator'
require 'xcframework_cli/spm/package'

RSpec.describe XCFrameworkCLI::Builder::Orchestrator do
  let(:orchestrator) { described_class.new({}) }
  let(:package_dir) { '/path/to/package' }
  let(:output_dir) { '/path/to/output' }

  let(:spm_config) do
    {
      package_dir: package_dir,
      targets: ['MyLibrary'],
      platforms: %w[ios ios-simulator],
      output_dir: output_dir,
      configuration: 'release',
      library_evolution: true
    }
  end

  describe '#spm_build' do
    let(:package_double) { instance_double(XCFrameworkCLI::SPM::Package) }
    let(:target_double) { instance_double(XCFrameworkCLI::SPM::Package::Target) }

    before do
      allow(File).to receive(:exist?).with(File.join(package_dir, 'Package.swift')).and_return(true)
      allow(XCFrameworkCLI::SPM::Package).to receive(:new).with(package_dir).and_return(package_double)
      allow(package_double).to receive(:library_targets).and_return([target_double])
      allow(package_double).to receive(:target).with('MyLibrary').and_return(target_double)
      allow(package_double).to receive(:platform_version).with('ios').and_return('15.0')
      allow(target_double).to receive(:name).and_return('MyLibrary')
      allow(target_double).to receive(:library?).and_return(true)
    end

    context 'when Package.swift not found' do
      before do
        allow(File).to receive(:exist?).with(File.join(package_dir, 'Package.swift')).and_return(false)
      end

      it 'returns failure with ValidationError message' do
        result = orchestrator.spm_build(spm_config)

        expect(result[:success]).to be false
        expect(result[:errors].first).to include('No Package.swift found')
      end
    end

    context 'when no targets specified' do
      let(:spm_config_no_targets) do
        {
          package_dir: package_dir,
          platforms: %w[ios],
          output_dir: output_dir
        }
      end

      before do
        allow(package_double).to receive(:library_targets).and_return([])
      end

      it 'returns failure with error' do
        result = orchestrator.spm_build(spm_config_no_targets)

        expect(result[:success]).to be false
        expect(result[:errors]).to include('No targets specified for build')
      end
    end

    context 'when target not found in package' do
      before do
        allow(package_double).to receive(:target).with('MyLibrary').and_return(nil)
      end

      it 'skips the target' do
        result = orchestrator.spm_build(spm_config)

        expect(result[:success]).to be false
        expect(result[:xcframework_paths]).to be_empty
      end
    end

    context 'when target is not a library' do
      before do
        allow(target_double).to receive(:library?).and_return(false)
      end

      it 'skips the target' do
        result = orchestrator.spm_build(spm_config)

        expect(result[:success]).to be false
        expect(result[:xcframework_paths]).to be_empty
      end
    end

    context 'when build succeeds' do
      let(:xcf_result) do
        {
          success: true,
          xcframework_path: '/path/to/output/MyLibrary.xcframework'
        }
      end

      before do
        allow(XCFrameworkCLI::SPM::XCFrameworkBuilder).to receive(:build_for_platforms).and_return(xcf_result)
      end

      it 'calls XCFrameworkBuilder with correct parameters' do
        expect(XCFrameworkCLI::SPM::XCFrameworkBuilder).to receive(:build_for_platforms).with(
          target: 'MyLibrary',
          platforms: %w[ios ios-simulator],
          package_dir: package_dir,
          output_dir: output_dir,
          configuration: 'release',
          library_evolution: true,
          version: '15.0'
        )

        orchestrator.spm_build(spm_config)
      end

      it 'returns success result' do
        result = orchestrator.spm_build(spm_config)

        expect(result[:success]).to be true
        expect(result[:xcframework_paths]).to include('/path/to/output/MyLibrary.xcframework')
        expect(result[:targets_completed]).to include('MyLibrary')
      end
    end

    context 'when build fails' do
      let(:xcf_result) do
        {
          success: false,
          errors: ['Build error occurred']
        }
      end

      before do
        allow(XCFrameworkCLI::SPM::XCFrameworkBuilder).to receive(:build_for_platforms).and_return(xcf_result)
      end

      it 'returns failure result with errors' do
        result = orchestrator.spm_build(spm_config)

        expect(result[:success]).to be false
        expect(result[:xcframework_paths]).to be_empty
        expect(result[:errors].first).to include('Build error occurred')
      end
    end

    context 'with multiple targets' do
      let(:multi_target_config) do
        {
          package_dir: package_dir,
          targets: %w[Library1 Library2],
          platforms: %w[ios],
          output_dir: output_dir
        }
      end

      let(:target1) { instance_double(XCFrameworkCLI::SPM::Package::Target, name: 'Library1', library?: true) }
      let(:target2) { instance_double(XCFrameworkCLI::SPM::Package::Target, name: 'Library2', library?: true) }

      before do
        allow(package_double).to receive(:target).with('Library1').and_return(target1)
        allow(package_double).to receive(:target).with('Library2').and_return(target2)

        allow(XCFrameworkCLI::SPM::XCFrameworkBuilder).to receive(:build_for_platforms).and_return(
          success: true,
          xcframework_path: '/path/to/output/Library.xcframework'
        )
      end

      it 'builds all specified targets' do
        expect(XCFrameworkCLI::SPM::XCFrameworkBuilder).to receive(:build_for_platforms).twice

        result = orchestrator.spm_build(multi_target_config)

        expect(result[:success]).to be true
        expect(result[:targets_completed].length).to eq(2)
      end
    end

    context 'with default configuration' do
      let(:minimal_config) do
        {
          package_dir: package_dir,
          targets: ['MyLibrary'],
          output_dir: output_dir
        }
      end

      before do
        allow(XCFrameworkCLI::SPM::XCFrameworkBuilder).to receive(:build_for_platforms).and_return(
          success: true,
          xcframework_path: '/path/to/output/MyLibrary.xcframework'
        )
      end

      it 'uses default platforms' do
        expect(XCFrameworkCLI::SPM::XCFrameworkBuilder).to receive(:build_for_platforms).with(
          hash_including(
            platforms: %w[ios ios-simulator],
            configuration: 'release',
            library_evolution: true
          )
        )

        orchestrator.spm_build(minimal_config)
      end
    end

    context 'when exception occurs' do
      before do
        allow(XCFrameworkCLI::SPM::Package).to receive(:new).and_raise(StandardError, 'Package load failed')
      end

      it 'returns failure result with error message' do
        result = orchestrator.spm_build(spm_config)

        expect(result[:success]).to be false
        expect(result[:errors]).to include('Package load failed')
      end
    end
  end
end
