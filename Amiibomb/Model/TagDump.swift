//
//  TagDump.swift
//  Amiibomb
//
//  Created by Paul Tavitian on 3/5/2022.
//

import Foundation

struct TagDump {
    let data: Data

    init(data: Data) throws {
        guard data.count >= 532 else { throw TagDumpError.invalidDataCount }

        self.data = data.subdata(in: 0..<min(532, data.count))
    }

    var headHex: String {
        return data[84..<88].map { .init(format: "%02hhx", $0) }.joined()
    }

    var tailHex: String {
        return data[88..<92].map { .init(format: "%02hhx", $0) }.joined()
    }

    var uid: Data {
        return data.subdata(in: 0..<9)
    }

    var writeCounter: Data {
        return data.subdata(in: 17..<19)
    }

    var keygenSalt: Data {
        return data.subdata(in: 96..<128)
    }

    static func pwd(uid: Data) throws -> Data {
        guard uid.count == 9 else { throw TagDumpError.invalidUID }

        var pwd: Data = .init(repeating: 0, count: 4)
        pwd[0] = 0xAA ^ (uid[1] ^ uid[4])
        pwd[1] = 0x55 ^ (uid[2] ^ uid[5])
        pwd[2] = 0xAA ^ (uid[4] ^ uid[6])
        pwd[3] = 0x55 ^ (uid[5] ^ uid[7])
        return pwd
    }

    func patchedDump(withUID newUID: Data) throws -> TagDump {
        guard newUID.count == 9 else { throw TagDumpError.invalidUID }

        guard let masterKeyPath: String = Bundle.main.path(forResource: "key_retail", ofType: "bin") else {
            throw TagDumpError.keyFileNotFound
        }

        let amiitool: Amiitool = try .init(path: masterKeyPath)

        var decrypted: Data = try amiitool.unpack(data)
        decrypted.replaceSubrange(468..<476, with: newUID.subdata(in: 0..<8))

        let encrypted: Data = amiitool.pack(decrypted)

        return try .init(data: encrypted)
    }
}
