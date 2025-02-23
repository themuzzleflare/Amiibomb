//
//  Amiitool.swift
//  Amiibomb
//
//  Created by Paul Tavitian on 20/5/2022.
//

import Foundation
import amiitool

typealias AmiiboKeys = UnsafeMutablePointer<nfc3d_amiibo_keys>
typealias OriginalTag = UnsafePointer<UInt8>
typealias ModifiedTag = UnsafeMutablePointer<UInt8>

struct Amiitool {
    let NTAG215_SIZE = 540
    let amiiboKeys: AmiiboKeys = .allocate(capacity: 1)
    
    init(path: String) throws {
        if !nfc3d_amiibo_load_keys(amiiboKeys, path) {
            print("Could not load keys from \"\(path)\"")
            throw AmiitoolError.loadKeysFailed
        }
    }
    
    func unpack(_ data: Data) throws -> Data {
        let original: OriginalTag = data.withUnsafeBytes { $0.baseAddress!.assumingMemoryBound(to: OriginalTag.self).pointee }
        
        let modified: ModifiedTag = .allocate(capacity: NTAG215_SIZE)
        
        if !nfc3d_amiibo_unpack(amiiboKeys, original, modified) {
            print("!!! WARNING !!!: Tag signature was NOT valid")
            throw AmiitoolError.unpackFailed
        }
        
        return .init(bytes: modified, count: NTAG215_SIZE)
    }
    
    func pack(_ data: Data) -> Data {
        let original: OriginalTag = data.withUnsafeBytes { $0.baseAddress!.assumingMemoryBound(to: OriginalTag.self).pointee }
        
        let modified: ModifiedTag = .allocate(capacity: NTAG215_SIZE)
        
        nfc3d_amiibo_pack(amiiboKeys, original, modified)
        
        return .init(bytes: modified, count: NTAG215_SIZE)
    }
}
