//
//  BundleExtension.swift
//  AppFoundation
//

import Foundation

extension Bundle {
  public var appVersion: String {
    guard let version = self.infoDictionary?["CFBundleShortVersionString"] as? String else {
      fatalError("Critical Error: Cannot Find 'CFBundleShortVersionString' in Info.Plist")
    }
    return version
  }
}
