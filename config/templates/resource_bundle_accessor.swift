import Foundation

private class BundleFinder {}

extension Bundle {
  @available(iOS 8.0, *)
  static let module: Bundle = {
    let bundleName = "{{PACKAGE_NAME}}_{{TARGET_NAME}}"
    let candidates = [
      Bundle.main.resourceURL,
      Bundle(for: BundleFinder.self).resourceURL,
      Bundle.main.bundleURL,
      Bundle.main.bundleURL.appendingPathComponent("Frameworks/{{TARGET_NAME}}.framework")
    ]

    for candidate in candidates {
      let bundlePath = candidate?.appendingPathComponent(bundleName + ".bundle")
      if let bundle = bundlePath.flatMap(Bundle.init(url:)) {
        return bundle
      }
    }
    fatalError("unable to find bundle named \(bundleName)")
  }()
}
