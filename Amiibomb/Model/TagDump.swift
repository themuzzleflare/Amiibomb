//
//  TagDump.swift
//  Amiibomb
//
//  Created by Paul Tavitian on 3/5/2022.
//

import Foundation

struct TagDump {
    let data: Data
    let headHex: String
    let tailHex: String
    let uid: Data
    
    init(data: Data) throws {
        guard data.count >= 532 else { throw TagDumpError.invalidDataCount }
        
        self.data = data
        self.headHex = data[84..<88].map { String(format: "%02hhx", $0) }.joined()
        self.tailHex = data[88..<92].map { String(format: "%02hhx", $0) }.joined()
        self.uid = data.subdata(in: 0..<9)
    }
    
    static func pwd(uid: Data) throws -> Data {
        guard uid.count == 9 else { throw TagDumpError.invalidUID }
        
        var pwd = Data(repeating: 0, count: 4)
        pwd[0] = 0xAA ^ (uid[1] ^ uid[4])
        pwd[1] = 0x55 ^ (uid[2] ^ uid[5])
        pwd[2] = 0xAA ^ (uid[4] ^ uid[6])
        pwd[3] = 0x55 ^ (uid[5] ^ uid[7])
        return pwd
    }
    
    func patchedDump(withUID newUID: Data) throws -> TagDump {
        guard newUID.count == 9 else { throw TagDumpError.invalidUID }
        
        guard let masterKey = Bundle.main.path(forResource: "key_retail", ofType: "bin") else {
            throw TagDumpError.keyFileNotFound
        }
        
        let amiitool = try Amiitool(path: masterKey)
        
        var decrypted = try amiitool.unpack(data)
        decrypted.replaceSubrange(468..<476, with: newUID.subdata(in: 0..<8))
        
        let encrypted = amiitool.pack(decrypted)
        
        return try TagDump(data: encrypted)
    }
}
