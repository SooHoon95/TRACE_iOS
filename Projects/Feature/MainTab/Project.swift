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
    .router
  ],
  testDependencies: []
)
