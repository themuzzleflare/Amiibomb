//
//  NFCMiFareTag+Extension.swift
//  Amiibomb
//
//  Created by Paul Tavitian on 1/5/2022.
//

import Foundation
import CoreNFC

extension NFCMiFareTag {
    func getVersion() async throws -> TagVersion {
        let data: Data = try await sendMiFareCommand(commandPacket: .init([NFCByte.cmdGetVersion.rawValue]))
        
        return try .init(data: data)
    }
    
    func fastRead(start: UInt8, end: UInt8, batchSize: UInt8) async throws -> Data {
        return try await fastReadInternal(start: start,
                                          end: end,
                                          batchSize: batchSize,
                                          accumulatedData: .init())
    }
    
    private func fastReadInternal(start: UInt8,
                                  end: UInt8,
                                  batchSize: UInt8,
                                  accumulatedData: Data) async throws -> Data {
        let batchEnd: UInt8 = min(start + batchSize - 1, end)
        
        let data: Data = try await sendMiFareCommand(commandPacket: .init([NFCByte.cmdFastRead.rawValue, start, batchEnd]))
        let accumulatedData: Data = accumulatedData + data
        
        if batchEnd < end {
            return try await self.fastReadInternal(start: batchEnd + 1,
                                                   end: end,
                                                   batchSize: batchSize,
                                                   accumulatedData: accumulatedData)
        } else {
            return accumulatedData
        }
    }
    
    func write(page: Int, data: Data) async throws {
        guard page < 255, data.count == 4 else {
            throw NFCMiFareTagError.invalidData
        }
        
        let commandPacket: Data = .init([NFCByte.cmdWrite.rawValue, UInt8(page)]) + data
        
        let data: Data = try await sendMiFareCommand(commandPacket: commandPacket)
        
        guard data.count == 1 else {
            throw NFCMiFareTagError.unknownError
        }
        
        switch data[0] {
        case 0x0A:
            return
        case 0x00:
            throw NFCMiFareTagError.invalidArgument
        case 0x01:
            throw NFCMiFareTagError.crcError
        case 0x04:
            throw NFCMiFareTagError.invalidAuthentication
        case 0x05:
            throw NFCMiFareTagError.eepromWriteError
        default:
            throw NFCMiFareTagError.unknownError
        }
    }
    
    func write(batch: [(page: Int, data: Data)],
               session: NFCTagReaderSession,
               progressCounter: Float = 0) async throws {
        if let write: (page: Int, data: Data) = batch.first {
            let progress: Float = progressCounter / 135
            let progressString: String = .init(format: "%.2f", progress * 100) + "%"
            let alertMessage: String = "Writing: \(progressString)"
            
            session.alertMessage = alertMessage
#if DEBUG
            print(alertMessage)
#endif
            
            try await self.write(page: write.page,
                                 data: write.data)
            try await self.write(batch: .init(batch[1..<batch.count]),
                                 session: session,
                                 progressCounter: progressCounter + 1)
        } else {
            return
        }
    }
}
