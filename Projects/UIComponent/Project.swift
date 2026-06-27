//
//  Project.swift
//  TraceManifests
//

import ProjectDescription
import ProjectDescriptionHelpers

let project = Project.framework(
  name: "UIComponent",
  platform: .iOS,
  dependencies: [
    .appFoundation,
    .domain
  ],
  testDependencies: []
)
