//
//  NTAG215TagError.swift
//  Amiibomb
//
//  Created by Paul Tavitian on 4/5/2022.
//

import Foundation

enum NTAG215TagError: Error {
  case invalidTagType
  case unknownError
}

extension NTAG215TagError: LocalizedError {
  var errorDescription: String? {
    switch self {
    case .invalidTagType:
      return "Invalid Tag Type"
    case .unknownError:
      return "Unknown NTAG215Tag Error"
    }
  }
}
