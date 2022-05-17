//
//  NTAG215Tag.swift
//  Amiibomb
//
//  Created by Paul Tavitian on 3/5/2022.
//

import Foundation
import CoreNFC

class NTAG215Tag {
  let tag: NFCMiFareTag
  let versionInfo: NFCMiFareTagVersionInfo
  let dump: TagDump
  let isLocked: Bool
  
  init(tag: NFCMiFareTag) async throws {
    let versionInfo = try await tag.getVersion()
    
    guard versionInfo.isNFC215 else {
      throw NTAG215TagError.invalidTagType
    }
    
    let data = try await tag.fastRead(start: 0, end: 0x86, batchSize: 0x20)
    
    guard let dump = TagDump(data: data) else {
      throw NTAG215TagError.unknownError
    }
    
    self.tag = tag
    self.versionInfo = versionInfo
    self.dump = dump
    self.isLocked = data[10] != 0 && data[11] != 0
  }
  
  func patchAndWriteDump(_ originalDump: TagDump, staticKey: TagKey, dataKey: TagKey, session: NFCTagReaderSession) async throws {
    let patchedDump = try originalDump.patchedDump(withUID: dump.uid, staticKey: staticKey, dataKey: dataKey)
    
    var writes = [(Int, Data)]()
    
    // Main Data
    for page in 3..<130 {
      let dataStartIndex = page * 4
      writes += [(page, patchedDump.data.subdata(in: dataStartIndex..<dataStartIndex + 4))]
    }
    
    writes += [(134, Data([0x80, 0x80, 0, 0]))] // PACK / RFUI
    writes += [(133, try TagDump.password(uid: dump.uid))] // Password
    writes += [(2, Data([patchedDump.data[8], patchedDump.data[9], 0x0F, 0xE0]))] // Lock Bits
    writes += [(130, Data([0x01, 0x00, 0x0F, 0x00]))] // Dynamic Lock Bits
    writes += [(131, Data([0x00, 0x00, 0x00, 0x04]))] // Config
    writes += [(132, Data([0x5F, 0x00, 0x00, 0x00]))] // Config
    
    try await tag.write(batch: writes, session: session)
  }
}
