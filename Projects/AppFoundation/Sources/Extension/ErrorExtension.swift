//
//  ErrorExtension.swift
//  AppFoundation
//

import Foundation

public extension Error {
  func toTraceError() -> TraceError? {
    if let traceErr = self as? TraceError {
      return traceErr
    } else if let networkErr = self as? NetworkError {
      return TraceError(code: networkErr.rawValue)
    } else {
      return nil
    }
  }
}
