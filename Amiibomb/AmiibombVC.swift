//
//  ReadVC.swift
//  Amiibomb
//
//  Created by Paul Tavitian on 30/4/2022.
//

import UIKit
import CoreNFC
import Alamofire
import CollectionConcurrencyKit

final class AmiibombVC: UIViewController {
  private var tagReaderSession: NFCTagReaderSession?
  private var tagWriterSession: NFCTagReaderSession?
  private var writeDelegate: WriteAmiiboDelegate?
  
  private let tableView = UITableView()
  
  private lazy var filePicker: UIDocumentPickerViewController = {
    let binPicker = UIDocumentPickerViewController(forOpeningContentTypes: [.bin], asCopy: true)
    binPicker.delegate = self
    return binPicker
  }()
  
  private var amiibos = [AmiiboObject]() {
    didSet {
      tableView.reloadData()
    }
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    view.addSubview(tableView)
    configureNavigation()
    configureTableView()
    refreshAmiibos()
  }
  
  override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()
    tableView.frame = view.bounds
  }
  
  func configureNavigation() {
    navigationItem.title = "Amiibomb"
    navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Import",
                                                       style: .plain,
                                                       target: self,
                                                       action: #selector(importButtonTapped))
    navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Scan",
                                                        style: .plain,
                                                        target: self,
                                                        action: #selector(scanButtonTapped))
  }
  
  func configureTableView() {
    tableView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    tableView.dataSource = self
    tableView.delegate = self
    tableView.register(UITableViewCell.self, forCellReuseIdentifier: "amiiboCell")
  }
  
  func refreshAmiibos() {
    Task {
      self.amiibos = await fetchAmiibos()
    }
  }
  
  func fetchAmiibos() async -> [AmiiboObject] {
    if let documentsDir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first,
       let contents = try? FileManager.default.contentsOfDirectory(at: documentsDir, includingPropertiesForKeys: nil) {
      return await contents.concurrentCompactMap { (url) in
        if let data = try? Data(contentsOf: url),
           let tagDump = TagDump(data: data) {
          return try? await AmiiboAPI.fetchAmiibo(head: tagDump.headHex, tail: tagDump.tailHex)
        } else {
          return nil
        }
      }
    } else {
      return [AmiiboObject]()
    }
  }
  
  @objc func importButtonTapped() {
    present(filePicker, animated: true)
  }
  
  @objc func scanButtonTapped() {
    guard NFCTagReaderSession.readingAvailable else {
      let alertController = UIAlertController(title: "Error",
                                              message: "NFC reading is not supported on this device.",
                                              preferredStyle: .alert)
      alertController.addAction(.dismiss)
      present(alertController, animated: true)
      return
    }
    
    tagReaderSession = NFCTagReaderSession(pollingOption: .iso14443, delegate: self)
    tagReaderSession?.alertMessage = "Hold amiibo/tag to back of device."
    tagReaderSession?.begin()
  }
}

extension AmiibombVC: UITableViewDataSource {
  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return amiibos.count
  }
  
  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: "amiiboCell", for: indexPath)
    let amiibo = amiibos[indexPath.row]
    
    Task {
      var config = UIListContentConfiguration.subtitleCell()
      config.text = amiibo.name
      config.secondaryText = amiibo.amiiboSeries
      config.imageProperties.reservedLayoutSize = CGSize(width: 64, height: 64)
      config.imageToTextPadding = 10
      config.image = UIImage(data: try await AmiiboAPI.amiiboImage(amiiboObject: amiibo))
      cell.contentConfiguration = config
    }
    return cell
  }
}

extension AmiibombVC: UITableViewDelegate {
  func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
    return 45
  }
  
  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    tableView.deselectRow(at: indexPath, animated: true)
    
    let amiibo = amiibos[indexPath.row]
    
    guard NFCTagReaderSession.readingAvailable else {
      let alertController = UIAlertController(title: "Error",
                                              message: "NFC reading is not supported on this device.",
                                              preferredStyle: .alert)
      alertController.addAction(.dismiss)
      present(alertController, animated: true)
      return
    }
    
    if let documentsDir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first,
       let contents = try? FileManager.default.contentsOfDirectory(at: documentsDir, includingPropertiesForKeys: nil) {
      let dumps: [TagDump] = contents.compactMap { (url) in
        if let data = try? Data(contentsOf: url),
           let tagDump = TagDump(data: data) {
          return tagDump
        } else {
          return nil
        }
      }
      
      if let dumpToWrite = dumps.first(where: { $0.headHex == amiibo.head && $0.tailHex == amiibo.tail }) {
        writeDelegate = WriteAmiiboDelegate(amiiboBin: dumpToWrite)
        
        if let writeDelegate = writeDelegate {
          tagWriterSession = NFCTagReaderSession(pollingOption: .iso14443, delegate: writeDelegate)
          tagWriterSession?.alertMessage = "\(amiibo.name) selected. Hold empty tag to back of device."
          tagWriterSession?.begin()
        }
      }
    }
  }
}

extension AmiibombVC: UIDocumentPickerDelegate {
  func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
    print(#function)
    
    guard let url = urls.first,
          let data = try? Data(contentsOf: url),
          let tagDump = TagDump(data: data)
    else {
      let alertController = UIAlertController(title: "Error",
                                              message: "Invalid amiibo file. Please select a valid file.",
                                              preferredStyle: .alert)
      alertController.addAction(.dismiss)
      present(alertController, animated: true)
      return
    }
    
    Task {
      do {
        try await AmiiboAPI.fetchAmiibo(head: tagDump.headHex, tail: tagDump.tailHex)
        
        if let documentsDir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
          let url = documentsDir.appendingPathComponent("\(tagDump.headHex)\(tagDump.tailHex).bin")
          try tagDump.data.write(to: url)
          
          refreshAmiibos()
        }
      } catch {
        var errorDescription: String {
          switch error {
          case let AFError.sessionTaskFailed(baseError):
            return baseError.localizedDescription
          case AFError.responseValidationFailed:
            return "Amiibo not recognised. Please try another file."
          default:
            return error.localizedDescription
          }
        }
        
        let alertController = UIAlertController(title: "Error",
                                                message: errorDescription,
                                                preferredStyle: .alert)
        alertController.addAction(.dismiss)
        present(alertController, animated: true)
      }
    }
  }
  
  func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
    print(#function)
  }
}

extension AmiibombVC: NFCTagReaderSessionDelegate {
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
        
        refreshAmiibos()
        
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
