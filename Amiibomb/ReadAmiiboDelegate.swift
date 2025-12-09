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
    
#if DEBUG
    deinit {
        print("deinit ReadAmiiboDelegate")
    }
#endif
    
    func tagReaderSessionDidBecomeActive(_ session: NFCTagReaderSession) {
#if DEBUG
        print(#function)
#endif
    }
    
    func tagReaderSession(_ session: NFCTagReaderSession, didInvalidateWithError error: Error) {
#if DEBUG
        print(#function)
#endif
    }
    
    func tagReaderSession(_ session: NFCTagReaderSession, didDetect tags: [NFCTag]) {
#if DEBUG
        print(#function)
#endif
        
        guard let tag: NFCTag = tags.first,
              case let .miFare(miFareTag): NFCTag = tag,
              miFareTag.mifareFamily == .ultralight else {
            session.invalidate(errorMessage: "Invalid tag type.")
            return
        }
        
        Task {
            do {
                try await session.connect(to: tag)
                
                let ntag215tag: AmiiboTag = try await .init(tag: miFareTag)
                
#if DEBUG
                print("Tag initialised")
                print("Locked: \(ntag215tag.isLocked.description)")
#endif
                
                guard ntag215tag.isLocked else {
                    session.alertMessage = "This is a blank tag."
                    session.invalidate()
                    return
                }
                
                let amiibo: AmiiboObject = try await AmiiboAPI.fetchAmiibo(head: ntag215tag.dump.headHex,
                                                                           tail: ntag215tag.dump.tailHex)
                
                if let documentsDir: URL = FileManager.default.urls(for: .documentDirectory,
                                                                    in: .userDomainMask).first {
                    let url: URL = documentsDir.appendingPathComponent("\(amiibo.head)\(amiibo.tail).bin")
                    try ntag215tag.dump.data.write(to: url)
                }
                
#if DEBUG
                dump(amiibo)
#endif
                
                await viewController?.refreshAmiibos()
                
                session.alertMessage = "\(amiibo.name) - \(amiibo.amiiboSeries)"
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
