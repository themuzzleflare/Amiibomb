//
//  TagDumpError.swift
//  Amiibomb
//
//  Created by Paul Tavitian on 4/5/2022.
//

import Foundation

enum TagDumpError: LocalizedError {
  case invalidUID
  case invalidDataCount
  case keyFileNotFound
  case unknownError
  
  var errorDescription: String? {
    switch self {
    case .invalidUID:
      return "Invalid UID"
    case .invalidDataCount:
      return "Invalid Data Count"
    case .keyFileNotFound:
      return "Key File Not Found"
    case .unknownError:
      return "Unknown Error"
    }
  }
}
