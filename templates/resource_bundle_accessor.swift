//
//  resource_bundle_accessor.swift
//  ios_theme_ui
//
//  Created by Phuong Doan Duy on 29/11/25.
//  Copyright © 2025 AAVN. All rights reserved.
//
//  Enhanced resource bundle lookup for XCFramework compatibility
//  Inspired by xccache (https://github.com/trinhngocthuyen/xccache)
//
//  This file overrides SPM's auto-generated resource_bundle_accessor.swift
//  to search for resource bundles in XCFramework distribution locations.
//
//  IMPORTANT: This template is for any XCFramework that embeds ios_theme_ui.
//  The bundle name will be ios_theme_ui's resource bundle (ios_theme_ui_ios_theme_ui).
//

import Foundation

/// Marker class for bundle identification
private class BundleFinder {}

extension Foundation.Bundle {
    /// The resource bundle associated with the current module.
    ///
    /// This implementation searches multiple locations to support:
    /// - XCFramework distribution (any XCFramework embedding ios_theme_ui resources)
    /// - App bundle distribution (bundle in app root)
    /// - SPM source builds (bundle in module)
    ///
    /// Search order (priority-based):
    /// 1. Main bundle resources (SPM source, direct embedding)
    /// 2. Current class bundle resources
    /// 3. Main bundle URL
    /// 4. XCFramework: Frameworks/[EmbeddingFramework].framework/ (primary distribution)
    /// 5. XCFramework: Frameworks/ios_theme_ui.framework/ (if distributed separately)
    static let module: Bundle = {
        let bundleName = "ios_theme_ui_ios_theme_ui"

        let candidates = [
            // 1. 🔥 PRIMARY: Bundle inside embedding XCFramework itself
            // The bundle is copied directly into [EmbeddingFramework].framework/ during build
            Bundle(for: BundleFinder.self).bundleURL,

            // 2. Bundle in main bundle resource URL (SPM source)
            Bundle.main.resourceURL,

            // 3. Bundle relative to current class resource URL
            Bundle(for: BundleFinder.self).resourceURL,

            // 4. Bundle in main bundle URL
            Bundle.main.bundleURL,

            // 5. Bundle in embedding XCFramework (app's Frameworks/)
            // When consumer app imports the embedding XCFramework
            Bundle.main.bundleURL
                .appendingPathComponent("Frameworks")
                .appendingPathComponent("ThemeShowcaseSDK.framework"),  // Example: ThemeShowcaseSDK

            // 6. Fallback: Bundle in ios_theme_ui XCFramework (if distributed separately)
            Bundle.main.bundleURL
                .appendingPathComponent("Frameworks")
                .appendingPathComponent("ios_theme_ui.framework"),
        ]

        // Try each candidate path until one works
        for candidate in candidates {
            let bundlePath = candidate?.appendingPathComponent("\(bundleName).bundle")
            if let bundle = bundlePath.flatMap(Bundle.init(url:)) {
                return bundle
            }
        }

        // If all candidates fail, provide detailed error message
        fatalError("""
            ❌ Unable to find resource bundle for ios_theme_ui.

            Searched the following paths:
            \(candidates.compactMap { $0?.path }.joined(separator: "\n"))

            Expected bundle name: \(bundleName).bundle

            This usually indicates a build configuration issue.
            Ensure the resource bundle from ios_theme_ui is properly included in your XCFramework.
            """)
    }()
}
