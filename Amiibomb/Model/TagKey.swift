//
//  TagKey.swift
//  Amiibomb
//
//  Created by Paul Tavitian on 3/5/2022.
//

import Foundation
import CryptoKit
import CryptoSwift

struct TagKey: Codable {
  private let data: Data
  
  var hmacKey: Data { return data.subdata(in: 0..<16) }
  var typeString: Data { return data.subdata(in: 16..<30) }
  var magicBytesSize: UInt8 { return data[31] }
  var magicBytes: Data { return data.subdata(in: 32..<(32 + Int(magicBytesSize))) }
  var xorPad: Data { return data.subdata(in: 48..<80) }
  
  init?(data: Data) {
    guard data.count == 80, data.startIndex == 0 else {
      return nil
    }
    
    guard data[31] <= 16 else {
      return nil
    }
    
    self.data = data
  }
  
  func derivedKey(uid: Data, writeCounter: Data, salt: Data) -> DerivedTagKey {
    var seed = Data(typeString)
    
    if magicBytesSize < 16 {
      seed.append(writeCounter)
    }
    
    seed.append(magicBytes)
    seed.append(uid[0..<8])
    seed.append(uid[0..<8])
    seed.append(contentsOf: (0..<32).map { salt[$0] ^ xorPad[$0] })
    
    let output = hmac(seed: seed, iteration: 0) + hmac(seed: seed, iteration: 1)[0..<16]
    
    return DerivedTagKey(aesKey: output.subdata(in: 0..<16),
                         aesIV: output.subdata(in: 16..<32),
                         hmacKey: output.subdata(in: 32..<48))
  }
  
  private func hmac(seed: Data, iteration: UInt8) -> Data {
    var hmac = CryptoKit.HMAC<SHA256>.init(key: SymmetricKey(data: hmacKey))
    let data = Data([(iteration >> 8) & 0x0f, (iteration >> 0) & 0x0f]) + seed
    hmac.update(data: data)
    return Data(hmac.finalize())
  }
}
