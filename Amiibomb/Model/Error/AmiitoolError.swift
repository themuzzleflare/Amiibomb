//
//  AmiitoolError.swift
//  Amiibomb
//
//  Created by Paul Tavitian on 24/4/2023.
//

import Foundation

enum AmiitoolError: LocalizedError {
    case loadKeysFailed
    case unpackFailed
    
    var errorDescription: String? {
        switch self {
        case .loadKeysFailed:
            return "Load Keys Failed"
        case .unpackFailed:
            return "Unpack Failed"
        }
    }
}
