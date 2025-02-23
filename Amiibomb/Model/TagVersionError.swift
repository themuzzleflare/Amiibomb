//
//  TagVersionError.swift
//  Amiibomb
//
//  Created by Paul Tavitian on 24/4/2023.
//

import Foundation

enum TagVersionError: LocalizedError {
    case invalidDataCount
    
    var errorDescription: String? {
        switch self {
        case .invalidDataCount:
            return "Invalid Data Count"
        }
    }
    
    var failureReason: String? {
        switch self {
        case .invalidDataCount:
            return "Data count must be 540"
        }
    }
}
