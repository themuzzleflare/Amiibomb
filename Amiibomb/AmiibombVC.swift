//
//  ReadVC.swift
//  Amiibomb
//
//  Created by Paul Tavitian on 30/4/2022.
//

import UIKit
import CoreNFC
import Alamofire
import AsyncAlgorithms

final class AmiibombVC: UIViewController {
    private var tagReaderSession: NFCReaderSession?
    private var tagWriterSession: NFCReaderSession?
    private var readDelegate: NFCTagReaderSessionDelegate?
    private var writeDelegate: NFCTagReaderSessionDelegate?
    
    private let tableView: UITableView = .init()
    
    private lazy var filePicker: UIDocumentPickerViewController = {
        let binPicker: UIDocumentPickerViewController = .init(forOpeningContentTypes: [.bin],
                                                              asCopy: true)
        binPicker.delegate = self
        return binPicker
    }()
    
    private var amiibos: [AmiiboObject] = .init() {
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
        navigationItem.leftBarButtonItem = .init(title: "Import",
                                                 style: .plain,
                                                 target: self,
                                                 action: #selector(importButtonTapped))
        navigationItem.rightBarButtonItem = .init(title: "Scan",
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
        if let documentsDir: URL = FileManager.default.urls(for: .documentDirectory,
                                                            in: .userDomainMask).first,
           let contents: [URL] = try? FileManager.default.contentsOfDirectory(at: documentsDir,
                                                                              includingPropertiesForKeys: nil) {
            return await .init(contents.async.compactMap { (url) in
                if let data: Data = try? .init(contentsOf: url),
                   let tagDump: TagDump = try? .init(data: data) {
                    return try? await AmiiboAPI.fetchAmiibo(head: tagDump.headHex,
                                                            tail: tagDump.tailHex)
                } else {
                    return nil
                }
            })
        } else {
            return .init()
        }
    }
    
    @objc func importButtonTapped() {
        present(filePicker, animated: true)
    }
    
    @objc func scanButtonTapped() {
        guard NFCTagReaderSession.readingAvailable else {
            let alertController: UIAlertController = .init(title: "Error",
                                                           message: "NFC reading is not supported on this device.",
                                                           preferredStyle: .alert)
            alertController.addAction(.dismiss)
            present(alertController, animated: true)
            return
        }
        
        readDelegate = ReadAmiiboDelegate(self)
        
        if let readDelegate {
            tagReaderSession = NFCTagReaderSession(pollingOption: .iso14443,
                                                   delegate: readDelegate)
            tagReaderSession?.alertMessage = "Hold amiibo/tag to back of device."
            tagReaderSession?.begin()
        }
    }
}

extension AmiibombVC: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return amiibos.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: UITableViewCell = tableView.dequeueReusableCell(withIdentifier: "amiiboCell",
                                                                  for: indexPath)
        let amiibo: AmiiboObject = amiibos[indexPath.row]
        
        Task {
            var config: UIListContentConfiguration = .subtitleCell()
            
            config.text = amiibo.name
            config.secondaryText = amiibo.amiiboSeries
            config.prefersSideBySideTextAndSecondaryText = true
            config.imageProperties.reservedLayoutSize = .init(width: 64, height: 64)
            config.imageToTextPadding = 10
            config.image = .init(data: try await AmiiboAPI.amiiboImage(amiiboObject: amiibo))
            
            cell.contentConfiguration = config
        }
        return cell
    }
}

extension AmiibombVC: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 45.0
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let amiibo: AmiiboObject = amiibos[indexPath.row]
        
        guard NFCTagReaderSession.readingAvailable else {
            let alertController: UIAlertController = .init(title: "Error",
                                                           message: "NFC reading is not supported on this device.",
                                                           preferredStyle: .alert)
            alertController.addAction(.dismiss)
            present(alertController, animated: true)
            return
        }
        
        if let documentsDir: URL = FileManager.default.urls(for: .documentDirectory,
                                                            in: .userDomainMask).first,
           let contents: [URL] = try? FileManager.default.contentsOfDirectory(at: documentsDir,
                                                                              includingPropertiesForKeys: nil) {
            let dumps: [TagDump] = contents.compactMap { (url) in
                if let data: Data = try? .init(contentsOf: url),
                   let tagDump: TagDump = try? .init(data: data) {
                    return tagDump
                } else {
                    return nil
                }
            }
            
            if let dumpToWrite: TagDump = dumps.first(where: { $0.headHex == amiibo.head && $0.tailHex == amiibo.tail }) {
                writeDelegate = WriteAmiiboDelegate(amiiboBin: dumpToWrite)
                
                if let writeDelegate {
                    tagWriterSession = NFCTagReaderSession(pollingOption: .iso14443,
                                                           delegate: writeDelegate)
                    tagWriterSession?.alertMessage = "\(amiibo.name) selected. Hold empty tag to back of device."
                    tagWriterSession?.begin()
                }
            }
        }
    }
}

extension AmiibombVC: UIDocumentPickerDelegate {
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
#if DEBUG
        print(#function)
#endif
        
        guard let url: URL = urls.first,
              let data: Data = try? .init(contentsOf: url),
              let tagDump: TagDump = try? .init(data: data)
        else {
            let alertController: UIAlertController = .init(title: "Error",
                                                           message: "Invalid amiibo file. Please select a valid file.",
                                                           preferredStyle: .alert)
            alertController.addAction(.dismiss)
            present(alertController, animated: true)
            return
        }
        
        Task {
            do {
                try await AmiiboAPI.fetchAmiibo(head: tagDump.headHex,
                                                tail: tagDump.tailHex)
                
                if let documentsDir: URL = FileManager.default.urls(for: .documentDirectory,
                                                                    in: .userDomainMask).first {
                    let url: URL = documentsDir.appendingPathComponent("\(tagDump.headHex)\(tagDump.tailHex).bin")
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
                
                let alertController: UIAlertController = .init(title: "Error",
                                                               message: errorDescription,
                                                               preferredStyle: .alert)
                alertController.addAction(.dismiss)
                present(alertController, animated: true)
            }
        }
    }
    
    func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
#if DEBUG
        print(#function)
#endif
    }
}
