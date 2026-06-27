//
//  Project.swift
//  TraceManifests
//

import ProjectDescription
import ProjectDescriptionHelpers

let project = Project.framework(
  name: "Networking",
  platform: .iOS,
  dependencies: [
    .appFoundation,
    .domain
  ],
  testDependencies: [

  ]
)
