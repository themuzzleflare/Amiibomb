//
//  AmiiboAPI.swift
//  Amiibomb
//
//  Created by Paul Tavitian on 30/4/2022.
//

import Foundation
import Alamofire

enum AmiiboAPI {
  @discardableResult
  static func fetchAmiibo(head: String, tail: String) async throws -> AmiiboObject {
    return try await AF.request("https://www.amiiboapi.com/api/amiibo/", parameters: ["id": "\(head)\(tail)"])
      .validate()
      .serializingDecodable(AmiiboResponse.self)
      .value
      .amiibo
  }
  
  static func amiiboImage(amiiboObject: AmiiboObject) async throws -> Data {
    return try await AF.request(amiiboObject.image)
      .serializingData()
      .value
  }
}
