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
    // Phase 2 backend products go here, e.g.:
    // "Supabase": .framework, "Auth": .framework, "PostgREST": .framework, "Storage": .framework
  ],
  baseSettings: .settings(configurations: Configuration.frameworkConfigure())
)
#endif

let package = Package(
  name: "TracePackages",
  dependencies: [
    // Secure token/credential storage (used by Infrastructure; needed for Phase 2 auth sessions).
    .package(url: "https://github.com/kishikawakatsumi/KeychainAccess.git", from: "4.2.2")

    // ── Phase 2 backend — add the same way, then wire `.external(...)` constants ──
    // .package(url: "https://github.com/supabase/supabase-swift.git", from: "2.0.0"),
  ]
)
