# frozen_string_literal: true

require 'fileutils'

module XCFrameworkCLI
  module SPM
    # Framework slice builder for a single SDK
    # Builds .framework bundle from Swift Package target using swift build + libtool
    class FrameworkSlice
      attr_reader :target, :sdk, :package_dir, :output_path, :configuration, :library_evolution, :tmpdir

      # Initialize framework slice builder
      #
      # @param target [String] Target name to build
      # @param sdk [Swift::SDK] SDK instance
      # @param package_dir [String] Package directory
      # @param output_path [String] Output path for .framework
      # @param configuration [String] Build configuration
      # @param library_evolution [Boolean] Enable library evolution
      # @param tmpdir [String, nil] Optional temporary directory
      def initialize(target:, sdk:, package_dir:, output_path:, configuration: 'release', library_evolution: true,
                     tmpdir: nil)
        @target = target
        @sdk = sdk
        @package_dir = package_dir
        @output_path = output_path
        @configuration = configuration
        @library_evolution = library_evolution
        @tmpdir = tmpdir || Dir.mktmpdir("xcframework-slice-#{target}-")
      end

      # Build framework slice
      #
      # @return [Hash] Build result with :success, :framework_path, :error
      def build
        Utils::Logger.info("Building #{target}.framework for #{sdk} (#{configuration})...")

        # Step 1: Execute swift build
        builder = Swift::Builder.new(
          package_dir: package_dir,
          target: target,
          sdk: sdk,
          configuration: configuration,
          library_evolution: library_evolution
        )

        build_result = builder.build
        unless build_result[:success]
          return {
            success: false,
            framework_path: nil,
            error: "Swift build failed: #{build_result[:error]}"
          }
        end

        @build_dir = build_result[:build_dir]
        @products_dir = build_result[:products_dir]

        # Step 2: Create framework structure
        create_framework_structure

        {
          success: true,
          framework_path: output_path,
          sdk: sdk
        }
      rescue StandardError => e
        Utils::Logger.error("Framework slice build failed: #{e.message}")
        {
          success: false,
          framework_path: nil,
          error: e.message
        }
      end

      private

      # Create complete framework structure
      #
      # @return [void]
      def create_framework_structure
        Utils::Logger.debug("Creating framework structure at #{output_path}")

        # Ensure output directory exists
        FileUtils.mkdir_p(File.dirname(output_path))
        FileUtils.mkdir_p(output_path)

        # IMPORTANT: Override resource accessor BEFORE creating binary
        # This ensures the .o file is included in libtool
        override_resource_bundle_accessor if has_resource_bundle?

        # Create framework components
        create_framework_binary
        create_info_plist
        create_headers
        create_modules

        # Copy resource bundle to framework (after binary is created)
        copy_resource_bundle if has_resource_bundle?
      end

      # Create framework binary using libtool
      #
      # @return [void]
      def create_framework_binary
        Utils::Logger.debug("Creating framework binary with libtool")

        # Find all .o files
        object_files = find_object_files

        if object_files.empty?
          raise Error, "No object files found for target #{target}"
        end

        Utils::Logger.debug("Found #{object_files.length} object files")

        # Create filelist for libtool
        filelist_path = File.join(tmpdir, 'objects.txt')
        File.write(filelist_path, object_files.join("\n"))

        # Execute libtool
        binary_path = File.join(output_path, module_name)
        cmd = [
          'libtool',
          '-static',
          '-o', binary_path,
          '-filelist', filelist_path
        ]

        Utils::Logger.debug("Executing: #{cmd.join(' ')}")
        require 'open3'
        stdout, stderr, status = Open3.capture3(*cmd)

        unless status.success?
          raise Error, "libtool failed: #{stderr}"
        end

        # Make binary executable
        FileUtils.chmod('+x', binary_path)
        Utils::Logger.debug("Created framework binary: #{binary_path}")
      end

      # Find object files from build
      #
      # @return [Array<String>] Paths to .o files
      def find_object_files
        build_subdir = File.join(products_dir, "#{module_name}.build")

        unless File.directory?(build_subdir)
          raise Error, "Build directory not found: #{build_subdir}"
        end

        object_files = Dir.glob(File.join(build_subdir, '**', '*.o'))
        object_files.map { |f| File.expand_path(f) }
      end

      # Create Info.plist
      #
      # @return [void]
      def create_info_plist
        Utils::Logger.debug('Creating Info.plist')

        info_plist_path = File.join(output_path, 'Info.plist')
        Utils::Template.render(
          'framework.info.plist',
          {
            MODULE_NAME: module_name,
            PLATFORM: platform_name,
            MIN_OS_VERSION: min_os_version
          },
          save_to: info_plist_path
        )
      end

      # Create Headers directory with umbrella header
      #
      # @return [void]
      def create_headers
        Utils::Logger.debug('Creating Headers')

        headers_dir = File.join(output_path, 'Headers')
        FileUtils.mkdir_p(headers_dir)

        # Copy Swift-generated header if it exists
        swift_header_pattern = File.join(products_dir, "#{module_name}.build", '*-Swift.h')
        swift_headers = Dir.glob(swift_header_pattern)

        headers_to_include = []

        swift_headers.each do |header|
          dest = File.join(headers_dir, File.basename(header))
          FileUtils.cp(header, dest)
          headers_to_include << File.basename(header)
          Utils::Logger.debug("Copied Swift header: #{File.basename(header)}")
        end

        # Create umbrella header
        umbrella_header_path = File.join(headers_dir, "#{module_name}-umbrella.h")
        umbrella_content = headers_to_include.map { |h| "#import <#{module_name}/#{h}>" }.join("\n")
        File.write(umbrella_header_path, umbrella_content)
        Utils::Logger.debug("Created umbrella header: #{module_name}-umbrella.h")
      end

      # Create Modules directory with modulemap and swiftmodule
      #
      # @return [void]
      def create_modules
        Utils::Logger.debug('Creating Modules')

        modules_dir = File.join(output_path, 'Modules')
        FileUtils.mkdir_p(modules_dir)

        # Create modulemap
        create_modulemap(modules_dir)

        # Copy Swift modules
        copy_swiftmodules(modules_dir)
      end

      # Create module.modulemap
      #
      # @param modules_dir [String] Modules directory path
      # @return [void]
      def create_modulemap(modules_dir)
        modulemap_path = File.join(modules_dir, 'module.modulemap')
        Utils::Template.render(
          'framework.modulemap',
          { MODULE_NAME: module_name },
          save_to: modulemap_path
        )
        Utils::Logger.debug('Created module.modulemap')
      end

      # Copy Swift module files
      #
      # @param modules_dir [String] Modules directory path
      # @return [void]
      def copy_swiftmodules(modules_dir)
        swiftmodule_dir = File.join(modules_dir, "#{module_name}.swiftmodule")
        FileUtils.mkdir_p(swiftmodule_dir)

        # Find swiftmodule files in build products
        module_files_pattern = File.join(products_dir, 'Modules', "#{module_name}.*")
        module_files = Dir.glob(module_files_pattern)

        # Also check for swiftinterface in build directory
        interface_pattern = File.join(products_dir, "#{module_name}.build", "#{module_name}.swiftinterface")
        module_files += Dir.glob(interface_pattern)

        if module_files.empty?
          Utils::Logger.warning("No Swift module files found for #{module_name}")
          return
        end

        module_files.each do |file|
          # Rename to include triple
          basename = File.basename(file)
          new_basename = basename.sub(module_name, sdk.triple)
          dest = File.join(swiftmodule_dir, new_basename)
          FileUtils.cp(file, dest)
          Utils::Logger.debug("Copied Swift module: #{new_basename}")
        end
      end

      # Get module name (C99-compatible)
      #
      # @return [String] Module name
      def module_name
        @module_name ||= target.gsub(/[^a-zA-Z0-9_]/, '_')
      end

      # Get platform name for Info.plist
      #
      # @return [String] Platform name
      def platform_name
        case sdk.name
        when :iphoneos
          'iPhoneOS'
        when :iphonesimulator
          'iPhoneSimulator'
        when :macos
          'MacOSX'
        when :appletvos
          'AppleTVOS'
        when :appletvsimulator
          'AppleTVSimulator'
        when :watchos
          'WatchOS'
        when :watchsimulator
          'WatchSimulator'
        when :xros
          'XROS'
        when :xrsimulator
          'XRSimulator'
        else
          sdk.name.to_s
        end
      end

      # Get minimum OS version
      #
      # @return [String] Minimum OS version
      def min_os_version
        sdk.version || '1.0'
      end

      # Get products directory
      #
      # @return [String] Products directory path
      def products_dir
        @products_dir ||= File.join(package_dir, '.build', sdk.triple, configuration)
      end

      # ============================================================================
      # Resource Bundle Handling
      # ============================================================================

      # Override resource bundle accessor for binary framework
      # This ensures Bundle.module works correctly in binary targets
      #
      # @return [void]
      def override_resource_bundle_accessor
        Utils::Logger.info('Overriding resource_bundle_accessor for binary framework')

        # Determine language (Swift or ObjC)
        template_name = use_clang? ? 'resource_bundle_accessor.m' : 'resource_bundle_accessor.swift'

        # Create override source file
        source_path = File.join(tmpdir, File.basename(template_name))
        obj_path = File.join(products_dir, "#{module_name}.build", "#{File.basename(source_path)}.o")

        # Render template
        Utils::Template.render(
          template_name,
          {
            PACKAGE_NAME: package_name,
            TARGET_NAME: target,
            MODULE_NAME: module_name
          },
          save_to: source_path
        )

        # Compile to object file
        compile_resource_accessor(source_path, obj_path)
      end

      # Compile resource bundle accessor to object file
      #
      # @param source_path [String] Source file path
      # @param obj_path [String] Output object file path
      # @return [void]
      def compile_resource_accessor(source_path, obj_path)
        FileUtils.mkdir_p(File.dirname(obj_path))

        if use_clang?
          # Compile Objective-C
          cmd = [
            'xcrun', 'clang',
            '-x', 'objective-c',
            '-target', sdk.triple(with_version: true),
            '-isysroot', sdk.sdk_path,
            '-o', obj_path,
            '-c', source_path
          ]
        else
          # Compile Swift
          cmd = [
            'xcrun', 'swiftc',
            '-emit-library', '-emit-object',
            '-module-name', module_name,
            '-target', sdk.triple(with_version: true),
            '-sdk', sdk.sdk_path,
            '-o', obj_path,
            source_path
          ]
        end

        Utils::Logger.debug("Compiling resource accessor: #{cmd.join(' ')}")
        require 'open3'
        stdout, stderr, status = Open3.capture3(*cmd)

        unless status.success?
          raise Error, "Failed to compile resource accessor: #{stderr}"
        end

        Utils::Logger.debug("Resource accessor compiled: #{obj_path}")
      end

      # Copy resource bundle to framework
      #
      # @return [void]
      def copy_resource_bundle
        Utils::Logger.info('Copying resource bundle to framework')

        bundle_path = resource_bundle_path
        dest_path = File.join(output_path, File.basename(bundle_path))

        # Resolve symlinks before copying
        resolve_resource_symlinks(bundle_path) if File.exist?(bundle_path)

        # Copy bundle
        FileUtils.cp_r(bundle_path, dest_path)
        Utils::Logger.debug("Copied resource bundle: #{File.basename(bundle_path)}")
      end

      # Resolve symlinks in resource bundle
      # SPM may create symlinks that need to be resolved for binary distribution
      #
      # @param bundle_path [String] Path to resource bundle
      # @return [void]
      def resolve_resource_symlinks(bundle_path)
        Utils::Logger.debug('Resolving symlinks in resource bundle')

        # Find all symlinks in bundle
        symlinks = Dir.glob(File.join(bundle_path, '**', '*')).select do |path|
          File.symlink?(path)
        end

        return if symlinks.empty?

        symlinks.each do |symlink_path|
          begin
            # Get real path
            real_path = File.realpath(symlink_path)

            # Remove symlink
            File.delete(symlink_path)

            # Copy real file/directory
            if File.directory?(real_path)
              FileUtils.cp_r(real_path, symlink_path)
            else
              FileUtils.cp(real_path, symlink_path)
            end

            Utils::Logger.debug("Resolved symlink: #{File.basename(symlink_path)}")
          rescue StandardError => e
            Utils::Logger.warning("Failed to resolve symlink #{symlink_path}: #{e.message}")
          end
        end
      end

      # Check if target uses Clang (C/ObjC) vs Swift
      # For now, assume Swift. Can be enhanced by checking target type
      #
      # @return [Boolean] True if using Clang
      def use_clang?
        # TODO: Parse Package.swift to determine target language
        # For now, assume all targets are Swift
        false
      end

      # Check if target has resource bundle
      #
      # @return [Boolean] True if resource bundle exists
      def has_resource_bundle?
        bundle_path = resource_bundle_path
        exists = File.directory?(bundle_path)
        Utils::Logger.debug("Checking for resource bundle at: #{bundle_path} - exists: #{exists}")
        exists
      end

      # Get resource bundle path
      #
      # @return [String] Path to resource bundle
      def resource_bundle_path
        bundle_name = "#{package_name}_#{target}"
        File.join(products_dir, "#{bundle_name}.bundle")
      end

      # Get package name
      #
      # @return [String] Package name
      def package_name
        @package_name ||= File.basename(package_dir)
      end
    end
  end
end
