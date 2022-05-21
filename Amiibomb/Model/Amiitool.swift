//
//  Amiitool.swift
//  Amiibomb
//
//  Created by Paul Tavitian on 20/5/2022.
//

import Foundation
import amiitool

let NTAG215_SIZE = 540

struct Amiitool {
  var amiiboKeys = UnsafeMutablePointer<nfc3d_amiibo_keys>.allocate(capacity: 1)
  
  init(path: String) {
    if (!nfc3d_amiibo_load_keys(amiiboKeys, path)) {
      print("Could not load keys from \(path)")
    } else {
      print("Loaded keys")
    }
  }
  
  func unpack(_ tag: Data) -> Data {
    let unsafeTag = tag.unsafeBytes
    let output = UnsafeMutablePointer<UInt8>.allocate(capacity: NTAG215_SIZE)
    
    if (!nfc3d_amiibo_unpack(amiiboKeys, unsafeTag, output)) {
      print("!!! WARNING !!!: Tag signature was NOT valid")
    } else {
      print("Unpacked tag")
    }
    
    return Data(bytes: output, count: NTAG215_SIZE)
  }
  
  func pack(_ plain: Data) -> Data {
    let unsafePlain = plain.unsafeBytes
    let newImage = UnsafeMutablePointer<UInt8>.allocate(capacity: NTAG215_SIZE)
    
    nfc3d_amiibo_pack(amiiboKeys, unsafePlain, newImage)
    
    return Data(bytes: newImage, count: NTAG215_SIZE)
  }
}
