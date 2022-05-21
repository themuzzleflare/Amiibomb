//
//  Data+Extension.swift
//  Amiibomb
//
//  Created by Paul Tavitian on 21/5/2022.
//

import Foundation

extension Data {
  var unsafeBytes: UnsafePointer<UInt8> {
    self.withUnsafeBytes { $0 }
  }
}
