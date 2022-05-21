//
//  NFCMiFareTag+Extension.swift
//  Amiibomb
//
//  Created by Paul Tavitian on 1/5/2022.
//

import Foundation
import CoreNFC
import CryptoSwift

extension NFCMiFareTag {
  func getVersion() async throws -> NFCMiFareTagVersionInfo {
    let data = try await sendMiFareCommand(commandPacket: Data([NFCByte.cmdGetVersion]))
    
    if let versionInfo = NFCMiFareTagVersionInfo(data: data) {
      return versionInfo
    } else {
      throw NFCMiFareTagError.unknownError
    }
  }
  
  func fastRead(start: UInt8, end: UInt8, batchSize: UInt8) async throws -> Data {
    return try await _fastRead(start: start, end: end, batchSize: batchSize, accumulatedData: Data())
  }
  
  private func _fastRead(start: UInt8, end: UInt8, batchSize: UInt8, accumulatedData: Data) async throws -> Data {
    let batchEnd = min(start + batchSize - 1, end)
    
    let data = try await sendMiFareCommand(commandPacket: Data([NFCByte.cmdFastRead, start, batchEnd]))
    let accumulatedData = accumulatedData + data
    
    if batchEnd < end {
      return try await self._fastRead(start: batchEnd + 1, end: end, batchSize: batchSize, accumulatedData: accumulatedData)
    } else {
      return accumulatedData
    }
  }
  
  func write(page: Int, data: Data) async throws {
    guard page < 255, data.count == 4 else {
      throw NFCMiFareTagError.invalidData
    }
    
    let commandPacket = Data([NFCByte.cmdWrite, UInt8(page)]) + data
    
    let data = try await sendMiFareCommand(commandPacket: commandPacket)
    
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
  
  func write(batch: [(page: Int, data: Data)], session: NFCTagReaderSession, progressCounter: Int = 0) async throws {
    if let write = batch.first {
      let progress = Float(progressCounter) / Float(135)
      let progressString = String(format: "%.2f", progress * 100) + "%"
      
      session.alertMessage = "Writing: \(progressString)"
      
      try await self.write(page: write.page, data: write.data)
      try await self.write(batch: Array(batch[1..<batch.count]), session: session, progressCounter: progressCounter + 1)
    } else {
      return
    }
  }
}
