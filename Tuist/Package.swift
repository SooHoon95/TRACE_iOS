// swift-tools-version: 5.9
@preconcurrency import PackageDescription

// External SPM dependency layer (modeled on TheReader). Tuist reads this, resolves the
// packages, and exposes each product as `.external(name:)` (see Dependency+Extension.swift).
// Run `mise exec -- tuist install` after editing, then `tuist generate`.

#if TUIST
@preconcurrency import ProjectDescription
import ProjectDescriptionHelpers

let packageSettings = PackageSettings(
  productTypes: [
    "KeychainAccess": .framework
  ],
  baseSettings: .settings(configurations: Configuration.frameworkConfigure())
)
#endif

let package = Package(
  name: "TracePackages",
  dependencies: [
    // Secure storage for the session JWT (used by Infrastructure's TokenStore).
    .package(url: "https://github.com/kishikawakatsumi/KeychainAccess.git", from: "4.2.2")
  ]
)
