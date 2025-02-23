//
//  TagVersion.swift
//  Amiibomb
//
//  Created by Paul Tavitian on 4/5/2022.
//

import Foundation

struct TagVersion {
    let header: UInt8
    let vendorID: UInt8
    let productType: UInt8
    let productSubtype: UInt8
    let majorProductVersion: UInt8
    let minorProductVersion: UInt8
    let storageSize: UInt8
    let protocolType: UInt8
    
    init(data: Data) throws {
        guard data.count == 8 else { throw TagVersionError.invalidDataCount }
        
        self.header = data[0]
        self.vendorID = data[1]
        self.productType = data[2]
        self.productSubtype = data[3]
        self.majorProductVersion = data[4]
        self.minorProductVersion = data[5]
        self.storageSize = data[6]
        self.protocolType = data[7]
    }
}

extension TagVersion {
    var isNFC215: Bool {
        return productType == 0x04 && storageSize == 0x11
    }
}
