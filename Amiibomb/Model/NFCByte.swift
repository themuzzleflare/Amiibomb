//
//  NFCByte.swift
//  Amiibomb
//
//  Created by Paul Tavitian on 20/5/2022.
//

import Foundation

enum NFCByte {
  static let keyFileSize = 80
  static let tagFileSize = 532
  static let pageSize = 4
  
  static let cmdGetVersion: UInt8 = 0x60
  static let cmdRead: UInt8 = 0x30
  static let cmdFastRead: UInt8 = 0x3A
  static let cmdWrite: UInt8 = 0xA2
  static let cmdCompWrite: UInt8 = 0xA0
  static let cmdReadCnt: UInt8 = 0x39
  static let cmdPwdAuth: UInt8 = 0x1B
  static let cmdReadSig: UInt8 = 0x3C
}
