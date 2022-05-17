//
//  TagDumpError.swift
//  Amiibomb
//
//  Created by Paul Tavitian on 4/5/2022.
//

import Foundation

enum TagDumpError: Error {
  case invalidUID
}

extension TagDumpError: LocalizedError {
  var errorDescription: String? {
    switch self {
    case .invalidUID:
      return "Invalid UID"
    }
  }
}
