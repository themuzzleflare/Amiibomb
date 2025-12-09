//
//  AmiiboTag.swift
//  Amiibomb
//
//  Created by Paul Tavitian on 3/5/2022.
//

import Foundation
import CoreNFC

struct AmiiboTag {
    let tag: NFCMiFareTag
    let versionInfo: TagVersion
    let dump: TagDump
    let isLocked: Bool
    
    init(tag: NFCMiFareTag) async throws {
        let versionInfo: TagVersion = try await tag.getVersion()
        
        guard versionInfo.isNFC215 else { throw AmiiboTagError.invalidTagType }
        
        let data: Data = try await tag.fastRead(start: 0, end: 0x86, batchSize: 0x20)
        
        let dump: TagDump = try .init(data: data)
        
        self.tag = tag
        self.versionInfo = versionInfo
        self.dump = dump
        isLocked = data[10] != 0 && data[11] != 0
    }
    
    func patchAndWriteDump(_ originalDump: TagDump, session: NFCTagReaderSession) async throws {
        let patchedDump: TagDump = try originalDump.patchedDump(withUID: dump.uid)
        
        var writes: [(Int, Data)] = .init()
        
        // Main Data
        for page in 3..<130 {
            let dataStartIndex: Int = page * 4
            writes += [(page, patchedDump.data.subdata(in: dataStartIndex..<dataStartIndex + 4))]
        }
        
        writes += [(134, .init([0x80, 0x80, 0, 0]))] // PACK / RFUI
        writes += [(133, try TagDump.pwd(uid: dump.uid))] // Password
        writes += [(2, .init([patchedDump.data[8], patchedDump.data[9], 0x0F, 0xE0]))] // Lock Bits
        writes += [(130, .init([0x01, 0x00, 0x0F, 0x00]))] // Dynamic Lock Bits
        writes += [(131, .init([0x00, 0x00, 0x00, 0x04]))] // Config
        writes += [(132, .init([0x5F, 0x00, 0x00, 0x00]))] // Config
        
        try await tag.write(batch: writes, session: session)
    }
}
