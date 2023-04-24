//
//  NTAG215TagError.swift
//  Amiibomb
//
//  Created by Paul Tavitian on 4/5/2022.
//

import Foundation

enum NTAG215TagError: LocalizedError {
  case invalidTagType
  case unknownError
  
  var errorDescription: String? {
    switch self {
    case .invalidTagType:
      return "Invalid Tag Type"
    case .unknownError:
      return "Unknown NTAG215Tag Error"
    }
  }
}
