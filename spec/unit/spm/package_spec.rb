# frozen_string_literal: true

require 'spec_helper'
require 'xcframework_cli/spm/package'

RSpec.describe XCFrameworkCLI::SPM::Package do
  let(:package_dir) { '/path/to/package' }
  let(:package_json) do
    {
      name: 'MyPackage',
      platforms: [
        { platformName: 'ios', version: '15.0' },
        { platformName: 'macos', version: '12.0' }
      ],
      targets: [
        {
          name: 'MyLibrary',
          type: 'regular',
          path: 'Sources/MyLibrary',
          sources: ['MyLibrary.swift'],
          dependencies: []
        },
        {
          name: 'MyTests',
          type: 'test',
          dependencies: [{ byName: ['MyLibrary'] }]
        },
        {
          name: 'MyExecutable',
          type: 'executable',
          dependencies: []
        }
      ],
      products: [
        {
          name: 'MyLibrary',
          type: 'library',
          targets: ['MyLibrary']
        }
      ],
      dependencies: [
        {
          name: 'Alamofire',
          url: 'https://github.com/Alamofire/Alamofire.git',
          requirement: { range: [{ lowerBound: '5.0.0', upperBound: '6.0.0' }] }
        }
      ]
    }.to_json
  end

  before do
    allow(File).to receive(:exist?).with(File.join(package_dir, 'Package.swift')).and_return(true)
    allow(File).to receive(:expand_path).with(package_dir).and_return(package_dir)
  end

  describe '#initialize' do
    let(:success_status) { instance_double(Process::Status, success?: true) }
    let(:failure_status) { instance_double(Process::Status, success?: false) }

    it 'loads package manifest' do
      expect(Open3).to receive(:capture3).with('swift', 'package', 'dump-package', '--package-path', package_dir)
                                         .and_return([package_json, '', success_status])

      package = described_class.new(package_dir)

      expect(package.package_dir).to eq(package_dir)
      expect(package.name).to eq('MyPackage')
    end

    it 'raises error if Package.swift not found' do
      allow(File).to receive(:exist?).with(File.join(package_dir, 'Package.swift')).and_return(false)

      expect do
        described_class.new(package_dir)
      end.to raise_error(XCFrameworkCLI::ValidationError, /No Package.swift found/)
    end

    it 'raises error if swift package dump-package fails' do
      expect(Open3).to receive(:capture3).with('swift', 'package', 'dump-package', '--package-path', package_dir)
                                         .and_return(['', 'error message', failure_status])

      expect do
        described_class.new(package_dir)
      end.to raise_error(XCFrameworkCLI::Error, /Failed to load Package.swift/)
    end

    it 'raises error on invalid JSON' do
      expect(Open3).to receive(:capture3).with('swift', 'package', 'dump-package', '--package-path', package_dir)
                                         .and_return(['invalid json', '', success_status])

      expect do
        described_class.new(package_dir)
      end.to raise_error(XCFrameworkCLI::Error, /Failed to parse Package.swift/)
    end
  end

  describe 'with loaded package' do
    let(:success_status) { instance_double(Process::Status, success?: true) }
    let(:package) do
      allow(Open3).to receive(:capture3).with('swift', 'package', 'dump-package', '--package-path', package_dir)
                                        .and_return([package_json, '', success_status])
      described_class.new(package_dir)
    end

    describe '#name' do
      it 'returns package name' do
        expect(package.name).to eq('MyPackage')
      end
    end

    describe '#platforms' do
      it 'returns platform versions' do
        expect(package.platforms).to eq('ios' => '15.0', 'macos' => '12.0')
      end
    end

    describe '#targets' do
      it 'returns all targets' do
        expect(package.targets.length).to eq(3)
        expect(package.targets.map(&:name)).to contain_exactly('MyLibrary', 'MyTests', 'MyExecutable')
      end
    end

    describe '#target' do
      it 'finds target by name' do
        target = package.target('MyLibrary')
        expect(target).not_to be_nil
        expect(target.name).to eq('MyLibrary')
      end

      it 'returns nil for non-existent target' do
        target = package.target('NonExistent')
        expect(target).to be_nil
      end
    end

    describe '#library_targets' do
      it 'returns only library targets' do
        targets = package.library_targets
        expect(targets.length).to eq(1)
        expect(targets[0].name).to eq('MyLibrary')
      end
    end

    describe '#executable_targets' do
      it 'returns only executable targets' do
        targets = package.executable_targets
        expect(targets.length).to eq(1)
        expect(targets[0].name).to eq('MyExecutable')
      end
    end

    describe '#binary_targets' do
      it 'returns empty array when no binary targets' do
        targets = package.binary_targets
        expect(targets).to be_empty
      end
    end

    describe '#platform_version' do
      it 'returns version for iOS' do
        expect(package.platform_version(:ios)).to eq('15.0')
      end

      it 'returns version for macOS' do
        expect(package.platform_version('macos')).to eq('12.0')
      end

      it 'returns nil for unsupported platform' do
        expect(package.platform_version(:tvos)).to be_nil
      end
    end

    describe '#has_target?' do
      it 'returns true for existing target' do
        expect(package.has_target?('MyLibrary')).to be true
      end

      it 'returns false for non-existent target' do
        expect(package.has_target?('NonExistent')).to be false
      end
    end

    describe '#products' do
      it 'returns products' do
        expect(package.products.length).to eq(1)
        expect(package.products[0][:name]).to eq('MyLibrary')
        expect(package.products[0][:type]).to eq('library')
        expect(package.products[0][:targets]).to eq(['MyLibrary'])
      end
    end

    describe '#dependencies' do
      it 'returns dependencies' do
        expect(package.dependencies.length).to eq(1)
        expect(package.dependencies[0][:name]).to eq('Alamofire')
        expect(package.dependencies[0][:url]).to eq('https://github.com/Alamofire/Alamofire.git')
      end
    end

    describe '#reload!' do
      it 'reloads package manifest' do
        new_json = { name: 'UpdatedPackage', platforms: [], targets: [], products: [], dependencies: [] }.to_json
        # Create fresh package instance for reload test
        package_instance = nil

        # First call for initialization
        allow(Open3).to receive(:capture3).with('swift', 'package', 'dump-package', '--package-path', package_dir)
                                          .and_return([package_json, '', success_status])
        package_instance = described_class.new(package_dir)

        # Second call for reload
        allow(Open3).to receive(:capture3).with('swift', 'package', 'dump-package', '--package-path', package_dir)
                                          .and_return([new_json, '', success_status])

        package_instance.reload!

        expect(package_instance.name).to eq('UpdatedPackage')
      end
    end
  end

  describe XCFrameworkCLI::SPM::Package::Target do
    let(:target) do
      described_class.new(
        name: 'MyLibrary',
        type: 'regular',
        path: 'Sources/MyLibrary',
        sources: ['MyLibrary.swift'],
        dependencies: []
      )
    end

    describe '#library?' do
      it 'returns true for regular targets' do
        expect(target.library?).to be true
      end

      it 'returns false for other target types' do
        executable = described_class.new(name: 'MyApp', type: 'executable')
        expect(executable.library?).to be false
      end
    end

    describe '#executable?' do
      it 'returns true for executable targets' do
        executable = described_class.new(name: 'MyApp', type: 'executable')
        expect(executable.executable?).to be true
      end

      it 'returns false for library targets' do
        expect(target.executable?).to be false
      end
    end

    describe '#test?' do
      it 'returns true for test targets' do
        test_target = described_class.new(name: 'MyTests', type: 'test')
        expect(test_target.test?).to be true
      end

      it 'returns false for library targets' do
        expect(target.test?).to be false
      end
    end

    describe '#binary?' do
      it 'returns true for binary targets' do
        binary = described_class.new(name: 'MyBinary', type: 'binary')
        expect(binary.binary?).to be true
      end

      it 'returns false for library targets' do
        expect(target.binary?).to be false
      end
    end

    describe '#macro?' do
      it 'returns true for macro targets' do
        macro = described_class.new(name: 'MyMacro', type: 'macro')
        expect(macro.macro?).to be true
      end

      it 'returns false for library targets' do
        expect(target.macro?).to be false
      end
    end

    describe '#plugin?' do
      it 'returns true for plugin targets' do
        plugin = described_class.new(name: 'MyPlugin', type: 'plugin')
        expect(plugin.plugin?).to be true
      end

      it 'returns false for library targets' do
        expect(target.plugin?).to be false
      end
    end

    describe '#module_name' do
      it 'returns C99-compatible identifier' do
        expect(target.module_name).to eq('MyLibrary')
      end

      it 'converts non-alphanumeric characters to underscores' do
        special_target = described_class.new(name: 'My-Library.Framework', type: 'regular')
        expect(special_target.module_name).to eq('My_Library_Framework')
      end
    end

    describe '#to_s' do
      it 'returns target name' do
        expect(target.to_s).to eq('MyLibrary')
      end
    end
  end
end
