//
//  Project.swift
//  TraceManifests
//

import ProjectDescription
import ProjectDescriptionHelpers

let project = Project.framework(
  name: "LeaveTrace",
  platform: .iOS,
  dependencies: [
    .appFoundation,
    .uiComponent,
    .domain,
    .router
  ],
  testDependencies: []
)
