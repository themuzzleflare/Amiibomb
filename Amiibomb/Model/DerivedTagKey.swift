//
//  DerivedTagKey.swift
//  Amiibomb
//
//  Created by Paul Tavitian on 4/5/2022.
//

import Foundation
import CryptoKit
import CryptoSwift

struct DerivedTagKey {
  let aesKey: Data
  let aesIV: Data
  let hmacKey: Data
  
  func hmac(_ input: Data) -> Data {
    var hmac = CryptoKit.HMAC<SHA256>.init(key: SymmetricKey(data: hmacKey))
    hmac.update(data: input)
    return Data(hmac.finalize())
  }
  
  func decrypt(_ input: Data) throws -> Data {
    let aes = try AES(key: [UInt8](aesKey), blockMode: CTR(iv: [UInt8](aesIV)))
    let output = try aes.decrypt([UInt8](input))
    return Data(output)
  }
}
