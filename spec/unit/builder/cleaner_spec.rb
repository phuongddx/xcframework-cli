# frozen_string_literal: true

require 'spec_helper'
require 'xcframework_cli/builder/cleaner'
require 'fileutils'
require 'tmpdir'

RSpec.describe XCFrameworkCLI::Builder::Cleaner do
  let(:output_dir) { Dir.mktmpdir }
  let(:framework_name) { 'MySDK' }
  let(:cleaner) { described_class.new(output_dir: output_dir, framework_name: framework_name) }

  after do
    FileUtils.rm_rf(output_dir)
  end

  describe '#initialize' do
    it 'sets output_dir and framework_name' do
      expect(cleaner.output_dir).to eq(output_dir)
      expect(cleaner.framework_name).to eq(framework_name)
    end
  end

  describe '#clean_archives' do
    it 'removes archive directories' do
      # Create test archives
      archive1 = File.join(output_dir, 'MySDK-iOS.xcarchive')
      archive2 = File.join(output_dir, 'MySDK-iOS-Simulator.xcarchive')
      FileUtils.mkdir_p(archive1)
      FileUtils.mkdir_p(archive2)

      cleaned = cleaner.clean_archives

      expect(cleaned).to include(archive1, archive2)
      expect(File.exist?(archive1)).to be false
      expect(File.exist?(archive2)).to be false
    end

    it 'returns empty array when no archives exist' do
      cleaned = cleaner.clean_archives
      expect(cleaned).to be_empty
    end

    it 'only removes directories, not files' do
      # Create a file that matches the pattern
      file = File.join(output_dir, 'MySDK-iOS.xcarchive')
      FileUtils.touch(file)

      cleaned = cleaner.clean_archives

      expect(cleaned).to be_empty
      expect(File.exist?(file)).to be true
    end
  end

  describe '#clean_xcframework' do
    it 'removes XCFramework directory' do
      xcframework_path = File.join(output_dir, "#{framework_name}.xcframework")
      FileUtils.mkdir_p(xcframework_path)

      result = cleaner.clean_xcframework

      expect(result).to be true
      expect(File.exist?(xcframework_path)).to be false
    end

    it 'returns false when XCFramework does not exist' do
      result = cleaner.clean_xcframework
      expect(result).to be false
    end
  end

  describe '#clean_derived_data' do
    it 'removes derived data directory' do
      derived_data_path = File.join(output_dir, 'DerivedData')
      FileUtils.mkdir_p(derived_data_path)

      result = cleaner.clean_derived_data

      expect(result).to be true
      expect(File.exist?(derived_data_path)).to be false
    end

    it 'returns false when derived data does not exist' do
      result = cleaner.clean_derived_data
      expect(result).to be false
    end
  end

  describe '#clean_all' do
    it 'cleans archives and xcframework by default' do
      # Create test artifacts
      archive = File.join(output_dir, 'MySDK-iOS.xcarchive')
      xcframework = File.join(output_dir, "#{framework_name}.xcframework")
      FileUtils.mkdir_p(archive)
      FileUtils.mkdir_p(xcframework)

      result = cleaner.clean_all

      expect(result[:archives_cleaned]).to include(archive)
      expect(result[:xcframework_cleaned]).to be true
      expect(result[:derived_data_cleaned]).to be false
      expect(result[:errors]).to be_empty
    end

    it 'cleans derived data when requested' do
      derived_data = File.join(output_dir, 'DerivedData')
      FileUtils.mkdir_p(derived_data)

      result = cleaner.clean_all(derived_data: true)

      expect(result[:derived_data_cleaned]).to be true
    end

    it 'skips cleaning when options are false' do
      archive = File.join(output_dir, 'MySDK-iOS.xcarchive')
      xcframework = File.join(output_dir, "#{framework_name}.xcframework")
      FileUtils.mkdir_p(archive)
      FileUtils.mkdir_p(xcframework)

      result = cleaner.clean_all(archives: false, xcframework: false)

      expect(result[:archives_cleaned]).to be_empty
      expect(result[:xcframework_cleaned]).to be false
      expect(File.exist?(archive)).to be true
      expect(File.exist?(xcframework)).to be true
    end

    it 'handles errors gracefully' do
      allow(cleaner).to receive(:clean_archives).and_raise(StandardError.new('Test error'))

      result = cleaner.clean_all

      expect(result[:errors]).to include('Test error')
    end
  end

  describe '#clean_archive' do
    it 'removes specific archive' do
      archive_path = File.join(output_dir, 'MySDK-iOS.xcarchive')
      FileUtils.mkdir_p(archive_path)

      result = cleaner.clean_archive(archive_path)

      expect(result).to be true
      expect(File.exist?(archive_path)).to be false
    end

    it 'returns false when archive does not exist' do
      result = cleaner.clean_archive('/nonexistent/path')
      expect(result).to be false
    end
  end

  describe '#output_dir_exists?' do
    it 'returns true when directory exists' do
      expect(cleaner.output_dir_exists?).to be true
    end

    it 'returns false when directory does not exist' do
      FileUtils.rm_rf(output_dir)
      expect(cleaner.output_dir_exists?).to be false
    end
  end

  describe '#ensure_output_dir' do
    it 'creates directory when it does not exist' do
      FileUtils.rm_rf(output_dir)

      result = cleaner.ensure_output_dir

      expect(result).to be true
      expect(File.directory?(output_dir)).to be true
    end

    it 'returns true when directory already exists' do
      result = cleaner.ensure_output_dir
      expect(result).to be true
    end
  end
end
