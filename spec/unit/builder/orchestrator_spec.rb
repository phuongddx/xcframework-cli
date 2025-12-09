# frozen_string_literal: true

require 'spec_helper'
require 'xcframework_cli/builder/orchestrator'

RSpec.describe XCFrameworkCLI::Builder::Orchestrator do
  let(:config) do
    {
      project_path: 'MyApp.xcodeproj',
      scheme: 'MySDK',
      framework_name: 'MySDK',
      output_dir: 'build',
      platforms: %w[ios ios-simulator],
      clean: true,
      include_debug_symbols: true
    }
  end

  let(:orchestrator) { described_class.new(config) }

  let(:cleaner) do
    instance_double(
      XCFrameworkCLI::Builder::Cleaner,
      clean_all: { archives_cleaned: [], xcframework_cleaned: false, errors: [] },
      ensure_output_dir: true
    )
  end

  let(:archiver) do
    instance_double(
      XCFrameworkCLI::Builder::Archiver,
      build_archives: [
        { success: true, archive_path: 'build/MySDK-iOS.xcarchive', platform: 'ios' },
        { success: true, archive_path: 'build/MySDK-iOS-Simulator.xcarchive', platform: 'ios-simulator' }
      ]
    )
  end

  let(:xcframework_builder) do
    instance_double(
      XCFrameworkCLI::Builder::XCFramework,
      create_xcframework: {
        success: true,
        xcframework_path: 'build/MySDK.xcframework',
        frameworks_count: 2
      }
    )
  end

  before do
    allow(XCFrameworkCLI::Builder::Cleaner).to receive(:new).and_return(cleaner)
    allow(XCFrameworkCLI::Builder::Archiver).to receive(:new).and_return(archiver)
    allow(XCFrameworkCLI::Builder::XCFramework).to receive(:new).and_return(xcframework_builder)
  end

  describe '#initialize' do
    it 'validates and sets configuration' do
      expect(orchestrator.config[:project_path]).to eq('MyApp.xcodeproj')
      expect(orchestrator.config[:scheme]).to eq('MySDK')
      expect(orchestrator.config[:framework_name]).to eq('MySDK')
    end

    it 'sets default platforms' do
      minimal_config = config.except(:platforms)
      orch = described_class.new(minimal_config)
      expect(orch.config[:platforms]).to eq(%w[ios ios-simulator])
    end

    it 'sets default clean option' do
      minimal_config = config.except(:clean)
      orch = described_class.new(minimal_config)
      expect(orch.config[:clean]).to be true
    end

    it 'raises error when required keys are missing' do
      expect do
        described_class.new(scheme: 'MySDK')
      end.to raise_error(ArgumentError, /Missing required configuration keys/)
    end
  end

  describe '#build' do
    it 'executes complete build workflow' do
      result = orchestrator.build

      expect(result[:success]).to be true
      expect(result[:xcframework_path]).to eq('build/MySDK.xcframework')
      expect(result[:archives].size).to eq(2)
      expect(result[:steps_completed]).to include('clean', 'archive', 'xcframework')
    end

    it 'cleans build artifacts when clean option is true' do
      orchestrator.build

      expect(cleaner).to have_received(:clean_all).with(
        archives: true,
        xcframework: true,
        derived_data: false
      )
    end

    it 'skips cleaning when clean option is false' do
      config[:clean] = false
      orch = described_class.new(config)

      allow(XCFrameworkCLI::Builder::Cleaner).to receive(:new).and_return(cleaner)
      allow(XCFrameworkCLI::Builder::Archiver).to receive(:new).and_return(archiver)
      allow(XCFrameworkCLI::Builder::XCFramework).to receive(:new).and_return(xcframework_builder)

      result = orch.build

      expect(cleaner).not_to have_received(:clean_all)
      expect(result[:steps_completed]).not_to include('clean')
    end

    it 'creates Archiver with correct configuration' do
      orchestrator.build

      expect(XCFrameworkCLI::Builder::Archiver).to have_received(:new).with(
        project_path: 'MyApp.xcodeproj',
        scheme: 'MySDK',
        output_dir: 'build',
        configuration: 'Release',
        build_settings: {}
      )
    end

    it 'builds archives for configured platforms' do
      orchestrator.build

      expect(archiver).to have_received(:build_archives).with(%w[ios ios-simulator], {})
    end

    it 'passes deployment target to archiver when configured' do
      config[:deployment_target] = '15.0'
      orch = described_class.new(config)

      allow(XCFrameworkCLI::Builder::Cleaner).to receive(:new).and_return(cleaner)
      allow(XCFrameworkCLI::Builder::Archiver).to receive(:new).and_return(archiver)
      allow(XCFrameworkCLI::Builder::XCFramework).to receive(:new).and_return(xcframework_builder)

      orch.build

      expect(archiver).to have_received(:build_archives).with(
        %w[ios ios-simulator],
        { deployment_target: '15.0' }
      )
    end

    it 'creates XCFramework with correct configuration' do
      orchestrator.build

      expect(XCFrameworkCLI::Builder::XCFramework).to have_received(:new).with(
        framework_name: 'MySDK',
        output_dir: 'build'
      )
    end

    it 'passes include_debug_symbols option to XCFramework builder' do
      orchestrator.build

      expect(xcframework_builder).to have_received(:create_xcframework).with(
        anything,
        include_debug_symbols: true
      )
    end

    it 'returns error when all archives fail' do
      allow(archiver).to receive(:build_archives).and_return([
                                                               { success: false, archive_path: nil, platform: 'ios', error: 'Build failed' }
                                                             ])

      result = orchestrator.build

      expect(result[:success]).to be false
      expect(result[:errors]).to include('All archive builds failed')
    end

    it 'returns error when XCFramework creation fails' do
      allow(xcframework_builder).to receive(:create_xcframework).and_return(
        { success: false, xcframework_path: nil, error: 'Creation failed' }
      )

      result = orchestrator.build

      expect(result[:success]).to be false
      expect(result[:errors]).to include('Creation failed')
    end

    it 'handles exceptions gracefully' do
      allow(cleaner).to receive(:clean_all).and_raise(StandardError.new('Cleaning error'))

      result = orchestrator.build

      expect(result[:success]).to be false
      expect(result[:errors]).to include('Cleaning error')
    end
  end

  describe '#build_archives_only' do
    it 'builds archives without creating XCFramework' do
      results = orchestrator.build_archives_only

      expect(results.size).to eq(2)
      expect(xcframework_builder).not_to have_received(:create_xcframework)
    end
  end

  describe '#create_xcframework_from_existing_archives' do
    it 'creates XCFramework from existing archive paths' do
      archive_paths = [
        'build/MySDK-iOS.xcarchive',
        'build/MySDK-iOS-Simulator.xcarchive'
      ]

      allow(File).to receive(:directory?).and_return(true)

      result = orchestrator.create_xcframework_from_existing_archives(archive_paths)

      expect(result[:success]).to be true
      expect(xcframework_builder).to have_received(:create_xcframework)
    end
  end
end
