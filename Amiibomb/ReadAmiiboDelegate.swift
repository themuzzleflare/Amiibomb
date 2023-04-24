//
//  ReadAmiiboDelegate.swift
//  Amiibomb
//
//  Created by Paul Tavitian on 23/4/2023.
//

import Foundation
import CoreNFC
import Alamofire

final class ReadAmiiboDelegate: NSObject, NFCTagReaderSessionDelegate {
  private weak var viewController: AmiibombVC?
  
  init(_ viewController: AmiibombVC) {
    self.viewController = viewController
  }
  
  deinit {
    print("deinit ReadAmiiboDelegate")
  }
  
  func tagReaderSessionDidBecomeActive(_ session: NFCTagReaderSession) {
    print(#function)
  }
  
  func tagReaderSession(_ session: NFCTagReaderSession, didInvalidateWithError error: Error) {
    print(#function)
  }
  
  func tagReaderSession(_ session: NFCTagReaderSession, didDetect tags: [NFCTag]) {
    print(#function)
    
    guard let tag = tags.first, case let .miFare(miFareTag) = tag, miFareTag.mifareFamily == .ultralight else {
      session.invalidate(errorMessage: "Invalid tag type.")
      return
    }
    
    Task {
      do {
        try await session.connect(to: tag)
        
        let ntag215tag = try await NTAG215Tag(tag: miFareTag)
        
        print("Tag initialised")
        print("Locked: \(ntag215tag.isLocked.description)")
        
        guard ntag215tag.isLocked else {
          session.alertMessage = "This is a blank tag. It can be used to write amiibo data."
          session.invalidate()
          return
        }
        
        let amiibo = try await AmiiboAPI.fetchAmiibo(head: ntag215tag.dump.headHex, tail: ntag215tag.dump.tailHex)
        
        if let documentsDir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
          let url = documentsDir.appendingPathComponent("\(amiibo.head)\(amiibo.tail).bin")
          try ntag215tag.dump.data.write(to: url)
        }
        
        dump(amiibo)
        
        await viewController?.refreshAmiibos()
        
        session.alertMessage = "\(amiibo.name)\n\(amiibo.amiiboSeries)"
        session.invalidate()
      } catch {
        var errorDescription: String {
          switch error {
          case let AFError.sessionTaskFailed(baseError):
            return baseError.localizedDescription
          case AFError.responseValidationFailed:
            return "Amiibo not recognised. Please try another amiibo/tag."
          default:
            return error.localizedDescription
          }
        }
        
        session.invalidate(errorMessage: errorDescription)
      }
    }
  }
}
