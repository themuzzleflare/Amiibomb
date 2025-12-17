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

#if DEBUG
    deinit {
        print("deinit WriteAmiiboDelegate")
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
              case .ultralight: NFCMiFareFamily = miFareTag.mifareFamily else {
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
