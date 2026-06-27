//
//  TraceError.swift
//  AppFoundation
//

import Foundation

public class TraceError: Error {
  private let code: Int

  public var define: TraceErrorDefine?
  public var description: String {
    return "문제가 발생했습니다.\n[error code: \(self.code)]"
  }

  public init(code: Int) {
    self.code = code
  }

  public init(_ errorDefine: TraceErrorDefine) {
    self.define = errorDefine
    self.code = errorDefine.rawValue
  }
}

extension TraceError: Equatable {
  public static func == (lhs: TraceError, rhs: TraceError) -> Bool {
    return lhs.code == rhs.code
  }
}
