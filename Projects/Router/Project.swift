//
//  Project.swift
//  TraceManifests
//

import ProjectDescription
import ProjectDescriptionHelpers

let project = Project.framework(
  name: "Router",
  platform: .iOS,
  dependencies: [
    .appFoundation,
    .uiComponent
  ],
  testDependencies: [

  ]
)
