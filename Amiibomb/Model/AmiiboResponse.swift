//
//  AmiiboResponse.swift
//  Amiibomb
//
//  Created by Paul Tavitian on 30/4/2022.
//

import Foundation

struct AmiiboResponse: Decodable {
    let amiibo: AmiiboObject
}

struct AmiiboObject: Decodable {
    let amiiboSeries: String
    let character: String
    let gameSeries: String
    let head: String
    let image: URL
    let name: String
    let tail: String
    let type: String
}
