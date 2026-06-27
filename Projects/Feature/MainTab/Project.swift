//
//  Project.swift
//  TraceManifests
//

import ProjectDescription
import ProjectDescriptionHelpers

let project = Project.framework(
  name: "MainTab",
  platform: .iOS,
  dependencies: [
    .appFoundation,
    .uiComponent,
    .domain,
    .router,
    // Tab roots hosted by the shell
    .feature(target: "Collection"),
    .feature(target: "Identity"),
    .feature(target: "LeaveTrace")
  ],
  testDependencies: []
)
