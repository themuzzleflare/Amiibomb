//
//  WriteAmiiboDelegate.swift
//  Amiibomb
//
//  Created by Paul Tavitian on 9/5/2022.
//

import Foundation
import CoreNFC

final class WriteAmiiboDelegate: NSObject, NFCTagReaderSessionDelegate {
    private let amiiboBin: TagDump
    
    init(amiiboBin: TagDump) {
        self.amiiboBin = amiiboBin
    }
    
    deinit {
        print("deinit WriteAmiiboDelegate")
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
                
                let ntag215tag = try await AmiiboTag(tag: miFareTag)
                
                print("Tag initialised")
                print("Locked: \(ntag215tag.isLocked.description)")
                
                guard !ntag215tag.isLocked else {
                    session.invalidate(errorMessage: "Tag is locked. Please use an unlocked tag.")
                    return
                }
                
                try await ntag215tag.patchAndWriteDump(amiiboBin, session: session)
                
                session.alertMessage = "Success!"
                session.invalidate()
            } catch {
                session.invalidate(errorMessage: error.localizedDescription)
            }
        }
    }
}
