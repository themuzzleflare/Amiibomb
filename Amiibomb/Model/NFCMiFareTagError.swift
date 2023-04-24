//
//  NFCMiFareTagError.swift
//  Amiibomb
//
//  Created by Paul Tavitian on 4/5/2022.
//

import Foundation

enum NFCMiFareTagError: LocalizedError {
  case invalidData
  case invalidArgument
  case crcError
  case invalidAuthentication
  case eepromWriteError
  case unknownError
  
  var errorDescription: String? {
    switch self {
    case .invalidData:
      return "Invalid Data"
    case .invalidArgument:
      return "Invalid Argument"
    case .crcError:
      return "CRC Error"
    case .invalidAuthentication:
      return "Invalid Authentication"
    case .eepromWriteError:
      return "EEPROM Write Error"
    case .unknownError:
      return "Unknown NFCMiFareTag Error"
    }
  }
}
