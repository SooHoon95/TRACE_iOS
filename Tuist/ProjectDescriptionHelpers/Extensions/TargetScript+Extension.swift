//
//  TargetScript+Extension.swift
//  Packages
//
//  Created by 송하민 on 7/11/24.
//

import ProjectDescription

public extension TargetScript {
  
  enum UtilityTool {
    case swiftLint
    case localization
    case swiftGen
    case licensePlist
  }
  
  static func prebuildScript(_ utility: UtilityTool, name: String) -> TargetScript {
    return .pre(script: utility.command, name: name)
  }
  
}

private extension TargetScript.UtilityTool {
  var command: String {
    switch self {
    // swiftlint/swiftgen binaries are git-ignored (large vendored tools); on CI / a fresh
    // clone they are absent, so guard each — run when present, skip with a warning otherwise.
    // The codegen output (Strings.swift) is committed, so skipping swiftgen on CI is safe.
    case .swiftLint:
      #"if [ -f "${PROJECT_DIR}/../../Tools/swiftlint" ]; then "${PROJECT_DIR}/../../Tools/swiftlint" --config "${PROJECT_DIR}/../UIComponent/Resources/swiftlint.yml"; else echo "warning: Tools/swiftlint not found — skipping lint"; fi"#
    case .localization:
      "${PROJECT_DIR}/../../Tools/generate_strings.sh"
    case .swiftGen:
      #"if [ -f "${PROJECT_DIR}/../../Tools/swiftgen" ]; then "${PROJECT_DIR}/../../Tools/swiftgen" config run --config "${PROJECT_DIR}/../UIComponent/Resources/swiftgen.yml"; else echo "warning: Tools/swiftgen not found — skipping codegen (committed output used)"; fi"#
    case .licensePlist:
      "${PROJECT_DIR}/../../../Tools/open_license.sh"
    }
  }
}
