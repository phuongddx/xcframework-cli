# frozen_string_literal: true

module XCFrameworkCLI
  module Project
    # Detects project type and extracts metadata
    class Detector
      # Detect project type in directory
      #
      # @param directory [String] Directory path to analyze
      # @return [Hash] Detection result with :type and :metadata
      def self.detect(directory = '.')
        dir = File.expand_path(directory)

        # Try Swift Package first
        if package_swift_exists?(dir)
          return {
            type: :spm,
            metadata: extract_spm_metadata(dir)
          }
        end

        # Try Xcode project
        xcode_path = find_xcode_project(dir)
        if xcode_path
          return {
            type: :xcode,
            metadata: extract_xcode_metadata(xcode_path)
          }
        end

        # Nothing found
        { type: :none, metadata: {} }
      end

      # Check if Package.swift exists
      #
      # @param directory [String] Directory path
      # @return [Boolean] true if Package.swift exists
      def self.package_swift_exists?(directory)
        File.exist?(File.join(directory, 'Package.swift'))
      end

      # Find Xcode project or workspace
      #
      # @param directory [String] Directory path
      # @return [String, nil] Path to .xcodeproj or .xcworkspace, or nil
      def self.find_xcode_project(directory)
        # Look for .xcworkspace first (higher priority)
        workspace = Dir.glob(File.join(directory, '*.xcworkspace')).first
        return workspace if workspace

        # Fall back to .xcodeproj
        Dir.glob(File.join(directory, '*.xcodeproj')).first
      end

      # Extract Swift Package metadata
      #
      # @param directory [String] Directory path
      # @return [Hash] Package metadata
      def self.extract_spm_metadata(directory)
        package = SPM::Package.new(directory)

        {
          package_name: package.name,
          targets: package.library_targets.map(&:name),
          platforms: package.platforms,
          package_dir: directory
        }
      rescue StandardError => e
        Utils::Logger.error("Failed to parse Package.swift: #{e.message}")
        {}
      end

      # Extract Xcode project metadata
      #
      # @param project_path [String] Path to .xcodeproj or .xcworkspace
      # @return [Hash] Project metadata
      def self.extract_xcode_metadata(project_path)
        schemes = extract_schemes(project_path)

        {
          project_path: project_path,
          project_name: File.basename(project_path, '.*'),
          schemes: schemes
        }
      rescue StandardError => e
        Utils::Logger.error("Failed to read Xcode project: #{e.message}")
        {}
      end

      # Extract schemes from Xcode project
      #
      # @param project_path [String] Path to .xcodeproj or .xcworkspace
      # @return [Array<String>] List of scheme names
      def self.extract_schemes(project_path)
        require 'open3'

        flag = project_path.end_with?('.xcworkspace') ? '-workspace' : '-project'
        cmd = ['xcodebuild', '-list', flag, project_path]
        stdout, _stderr, status = Open3.capture3(*cmd)

        return [] unless status.success?

        parse_schemes_from_output(stdout)
      end

      # Parse schemes from xcodebuild -list output
      #
      # @param output [String] Command output
      # @return [Array<String>] Scheme names
      def self.parse_schemes_from_output(output)
        schemes = []
        in_schemes_section = false

        output.each_line do |line|
          line = line.strip

          # Start of schemes section
          if line == 'Schemes:'
            in_schemes_section = true
            next
          end

          # End of schemes section (empty line or new section)
          break if in_schemes_section && (line.empty? || line.end_with?(':'))

          # Extract scheme name
          schemes << line if in_schemes_section && !line.empty?
        end

        schemes
      end
    end
  end
end
