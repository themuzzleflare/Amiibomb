//
//  NFCMiFareTagVersionInfo.swift
//  Amiibomb
//
//  Created by Paul Tavitian on 4/5/2022.
//

import Foundation

struct NFCMiFareTagVersionInfo {
  private let data: Data
  
  var header: UInt8 { return data[0] }
  var vendorID: UInt8 { return data[1] }
  var productType: UInt8 { return data[2] }
  var productSubtype: UInt8 { return data[3] }
  var majorProductVersion: UInt8 { return data[4] }
  var minorProductVersion: UInt8 { return data[5] }
  var storageSize: UInt8 { return data[6] }
  var protocolType: UInt8 { return data[7] }
  
  init?(data: Data) {
    guard data.count == 8 else { return nil }
    self.data = data
  }
}

extension NFCMiFareTagVersionInfo {
  var isNFC215: Bool {
    return productType == 0x04 && storageSize == 0x11
  }
}
