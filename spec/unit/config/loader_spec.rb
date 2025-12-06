# frozen_string_literal: true

require 'spec_helper'
require 'tempfile'

RSpec.describe XCFrameworkCLI::Config::Loader do
  describe '.load_file' do
    context 'with valid YAML file' do
      it 'loads configuration successfully' do
        config = {
          'project' => {
            'name' => 'TestSDK',
            'xcode_project' => 'TestSDK.xcodeproj'
          },
          'frameworks' => [
            {
              'name' => 'TestSDK',
              'scheme' => 'TestSDK',
              'platforms' => ['ios', 'ios-simulator']
            }
          ]
        }

        Tempfile.create(['test', '.yml']) do |file|
          file.write(config.to_yaml)
          file.rewind

          result = described_class.load_file(file.path)
          expect(result[:project][:name]).to eq('TestSDK')
          expect(result[:frameworks].first[:name]).to eq('TestSDK')
        end
      end
    end

    context 'with valid JSON file' do
      it 'loads configuration successfully' do
        config = {
          project: {
            name: 'TestSDK',
            xcode_project: 'TestSDK.xcodeproj'
          },
          frameworks: [
            {
              name: 'TestSDK',
              scheme: 'TestSDK',
              platforms: ['ios', 'ios-simulator']
            }
          ]
        }

        Tempfile.create(['test', '.json']) do |file|
          file.write(config.to_json)
          file.rewind

          result = described_class.load_file(file.path)
          expect(result[:project][:name]).to eq('TestSDK')
        end
      end
    end

    context 'with non-existent file' do
      it 'raises FileNotFoundError' do
        expect do
          described_class.load_file('non_existent.yml')
        end.to raise_error(XCFrameworkCLI::FileNotFoundError)
      end
    end

    context 'with invalid YAML syntax' do
      it 'raises ConfigError' do
        Tempfile.create(['invalid', '.yml']) do |file|
          file.write("invalid: yaml: syntax:\n  - bad")
          file.rewind

          expect do
            described_class.load_file(file.path)
          end.to raise_error(XCFrameworkCLI::ConfigError, /Invalid YAML syntax/)
        end
      end
    end

    context 'with invalid JSON syntax' do
      it 'raises ConfigError' do
        Tempfile.create(['invalid', '.json']) do |file|
          file.write('{ invalid json }')
          file.rewind

          expect do
            described_class.load_file(file.path)
          end.to raise_error(XCFrameworkCLI::ConfigError, /Invalid JSON syntax/)
        end
      end
    end
  end

  describe '.validate' do
    context 'with valid configuration' do
      it 'returns the configuration' do
        config = {
          project: {
            name: 'TestSDK',
            xcode_project: 'TestSDK.xcodeproj'
          },
          frameworks: [
            {
              name: 'TestSDK',
              scheme: 'TestSDK',
              platforms: ['ios']
            }
          ]
        }

        result = described_class.validate(config)
        expect(result).to eq(config)
      end
    end

    context 'with missing required fields' do
      it 'raises ValidationError' do
        config = {
          project: {
            name: 'TestSDK'
            # Missing xcode_project
          },
          frameworks: []
        }

        expect do
          described_class.validate(config)
        end.to raise_error(XCFrameworkCLI::ValidationError)
      end
    end

    context 'with invalid platform' do
      it 'raises ValidationError' do
        config = {
          project: {
            name: 'TestSDK',
            xcode_project: 'TestSDK.xcodeproj'
          },
          frameworks: [
            {
              name: 'TestSDK',
              scheme: 'TestSDK',
              platforms: ['invalid-platform']
            }
          ]
        }

        expect do
          described_class.validate(config)
        end.to raise_error(XCFrameworkCLI::ValidationError, /invalid platform/)
      end
    end
  end
end

