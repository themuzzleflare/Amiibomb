//
//  NFCByte.swift
//  Amiibomb
//
//  Created by Paul Tavitian on 20/5/2022.
//

import Foundation

enum NFCByte: UInt8 {
  case cmdGetVersion = 0x60
  case cmdRead = 0x30
  case cmdFastRead = 0x3A
  case cmdWrite = 0xA2
  case cmdCompWrite = 0xA0
  case cmdReadCnt = 0x39
  case cmdPwdAuth = 0x1B
  case cmdReadSig = 0x3C
}
