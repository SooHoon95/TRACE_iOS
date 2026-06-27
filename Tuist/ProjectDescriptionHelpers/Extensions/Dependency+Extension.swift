//
//  Dependency+Extension.swift
//  Packages
//
//  Created by 송하민 on 7/11/24.
//

import ProjectDescription

public extension TargetDependency {

  // MARK: - External (SPM via Tuist/Package.swift)
  static let keychainAccess: TargetDependency = .external(name: "KeychainAccess")
  // Phase 2 backend, e.g.: static let supabase: TargetDependency = .external(name: "Supabase")

  // MARK: - Local modules
  static let appFoundation: TargetDependency = .project(target: "AppFoundation", path: .relativeToRoot("Projects/AppFoundation"))
  static let networking: TargetDependency = .project(target: "Networking", path: .relativeToRoot("Projects/Network"))
  static let uiComponent: TargetDependency = .project(target: "UIComponent", path: .relativeToRoot("Projects/UIComponent"))
  static let router: TargetDependency = .project(target: "Router", path: .relativeToRoot("Projects/Router"))
  static let domain: TargetDependency = .project(target: "Domain", path: .relativeToRoot("Projects/Domain"))
  static let infrastructure: TargetDependency = .project(target: "Infrastructure", path: .relativeToRoot("Projects/Infrastructure"))

  static func feature(target: String) -> TargetDependency {
    return .project(target: target, path: .featurePath(target))
  }

}
