//
//  WMFileTableViewCell.swift
//  WebimClientLibrary_Example
//
//  Created by EVGENII Loshchenko on 23.12.2021.
//  Copyright © 2021 Webim. All rights reserved.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all
//  copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//  SOFTWARE.
//

import UIKit
import WebimClientLibrary

class FileMessage: WMMessageTableCell, WMDocumentDownloadTaskDelegate {
    @IBOutlet var fileName: UILabel!
    @IBOutlet var fileDescription: UILabel?
    @IBOutlet var downloadStatusLabel: UILabel?
    @IBOutlet var fileStatus: UIButton!
    @IBOutlet var fileDownloadIndicator: CircleProgressIndicator?
    
    
    var defaultFileImageColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)
    var defaultFileNameColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)
    var defaultFileDescriptionColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 0.7)
    var isForOperator = false
    
    var documentDownloadTask: WMDocumentDownloadTask?
    
    private var successDownloadFileImage: UIImage? {
        let config = config as? WMFileCellConfig
        let image = config?.readyFileImage ?? .loadImageFromWidget(named: "FileDownloadSuccess")
        let color = config?.successDownloadedFileImageColor ?? defaultFileImageColor
        return image?.colour(color)
    }
    
    private var downloadFileImage: UIImage? {
        let config = config as? WMFileCellConfig
        let image = config?.downloadFileImage ?? .loadImageFromWidget(named: "FileDownloadButton")
        let color = config?.readyToDownloadFileImageColor ?? defaultFileImageColor
        return image?.colour(color)
    }
    
    private var uploadFileImage: UIImage? {
        let config = config as? WMFileCellConfig
        let image = config?.uploadFileImage ?? .loadImageFromWidget(named: "FileUploadButtonVisitor")
        let color = config?.uploadFileImageColor ?? defaultFileImageColor
        return image?.colour(color)
    }
    
    private var errorFileImage: UIImage? {
        let config = config as? WMFileCellConfig
        let image = config?.errorFileImage ?? .loadImageFromWidget(named: "FileDownloadError")
        let color = config?.errorFileImageColor ?? defaultFileImageColor
        return image?.colour(color)
    }
    
    static let byteCountFormatter: ByteCountFormatter = {
        let byteCountFormatter = ByteCountFormatter()
        byteCountFormatter.allowedUnits = .useAll
        byteCountFormatter.countStyle = .file
        byteCountFormatter.includesUnit = true
        byteCountFormatter.isAdaptive = true
        return byteCountFormatter
    }()
    
    override func setMessage(message: Message) {
        super.setMessage(message: message)
        let attachment = message.getData()?.getAttachment()
        var fileInfo: FileInfo?
        if let quote = message.getQuote() {
            fileInfo = quote.getMessageAttachment()
        } else {
            fileInfo = message.getData()?.getAttachment()?.getFileInfo()
        }
        
        let fileSize = fileInfo?.getSize() ?? -1
        let sendStatus = message.getSendStatus() == .sent
        
        if sendStatus {
            if let fileURL = WMDownloadFileManager.shared.urlFromFileInfo(fileInfo) {
                self.documentDownloadTask = WMDocumentDownloadTask.documentDownloadTaskFor(url: fileURL, fileSize: fileSize, delegate: self)
            }
            self.isForOperator = false
            self.fileName?.text = fileInfo?.getFileName()
            resetFileStatus()
        } else {
            self.fileName?.text = "Uploading file".localized
            self.fileStatus.setBackgroundImage(
                uploadFileImage,
                for: .normal
            )
            self.fileDescription?.text = "File is being sent".localized
        }
        
        let isVisitor = message.isVisitorType()
        self.defaultFileImageColor = isVisitor ? visitorFileImageColor : operatorFileImageColor
        self.defaultFileNameColor = isVisitor ? visitorFileNameColor : operatorFileNameColor
        self.defaultFileDescriptionColor = isVisitor ? visitorFileDescriptionColor : operatorFileDescriptionColor
        self.fileDownloadIndicator?.setDefaultSetup()
        self.fileName?.textColor = defaultFileNameColor
        self.fileDescription?.textColor = defaultFileDescriptionColor
        self.downloadStatusLabel?.text = ""
        
        switch attachment?.getState() {
        case .ready:
            resetFileStatus()
            break
        case .upload:
            self.fileDescription?.text = "Sending".localized
            self.fileStatus.setBackgroundImage(
                downloadFileImage,
                for: .normal
            )
            self.fileStatus.isUserInteractionEnabled = false
            break
        case .error:
            self.fileDescription?.text = message.getData()?.getAttachment()?.getErrorMessage()
            self.defaultFileImageColor = wmCoral
            self.defaultFileNameColor = wmCoral
            self.fileName?.textColor = defaultFileNameColor
            self.fileDescription?.lineBreakMode = .byWordWrapping
            self.fileDescription?.font = UIFont.systemFont(ofSize: 11)
            self.fileStatus.setBackgroundImage(
                errorFileImage,
                for: .normal
            )
            self.fileStatus.isUserInteractionEnabled = false
            break
        default:
            break
        }
    }
    
    override func applyConfig() {
        super.applyConfig()
        
        if let titleAttributes = config?.titleAttributes {
            fileName.attributedText = NSAttributedString(
                string: fileName.text ?? "",
                attributes: titleAttributes
            )
        }
        
        if let subtitleAttributes = config?.subtitleAttributes {
            fileDescription?.attributedText = NSAttributedString(
                string: fileName.text ?? "",
                attributes: subtitleAttributes
            )
        }
    }
    
    @IBAction func openFile(_ sender: Any) {
        guard fileStatus.isUserInteractionEnabled else { return }
        if documentDownloadTask?.isDownloaded ?? false {
            self.fileStatus.setBackgroundImage(
                successDownloadFileImage,
                for: .normal
            )
            delegate?.openFile(message: self.message, url: documentDownloadTask?.localFileUrl)
        } else {
            self.documentDownloadTask?.downloadFile()
        }
    }
    
    func fileDownloadFaild(downloadFileUrl: URL) {
        if documentDownloadTask?.fileURL != downloadFileUrl {
            return
        }
        print("fileDownloadFaild \(downloadFileUrl)")
        resetFileStatus()
    }
    
    func updateFileDownloadProgress(downloadFileUrl: URL, progress: Float, localFileUrl: URL?) {
        if documentDownloadTask?.fileURL != downloadFileUrl {
            print("wrong cell progress ")
            return
        }
        if localFileUrl != nil {
            self.fileDownloadIndicator?.isHidden = true
            self.fileStatus.isHidden = false
            self.fileStatus.setBackgroundImage(
                successDownloadFileImage,
                for: .normal
            )
            self.downloadStatusLabel?.text = ""
            delegate?.openFile(message: self.message, url: localFileUrl)
        } else {
            self.fileStatus.isHidden = true
            self.downloadStatusLabel?.text = ""

            if self.fileDownloadIndicator?.isHidden ?? false {
                self.fileDownloadIndicator?.isHidden = false
                self.fileDownloadIndicator?.enableRotationAnimation()
                self.fileStatus.isHidden = true
            }
            self.fileDownloadIndicator?.setProgressWithAnimation(
                duration: 0.1,
                value: progress
            )
            self.downloadStatusLabel?.text = "\(Int(progress * 100))%"
        }
    }
    
    @objc func resetFileStatus() {
        self.fileStatus.isHidden = false
        self.downloadStatusLabel?.text = ""
        self.fileDownloadIndicator?.isHidden = true
        let fileSize = message.getData()?.getAttachment()?.getFileInfo().getSize() ?? -1
        self.fileDescription?.text = FileMessage.byteCountFormatter.string(fromByteCount: fileSize)
        if self.documentDownloadTask?.isFileExist() ?? false {
            self.fileStatus.setBackgroundImage(
                successDownloadFileImage,
                for: .normal
            )
        } else {
            self.fileStatus.setBackgroundImage(
                downloadFileImage,
                for: .normal
            )
        }
        self.fileStatus.isUserInteractionEnabled = true
    }
    
    override func initialSetup() -> Bool {
        let setup = super.initialSetup()
        if setup {
            let tapGesture = UITapGestureRecognizer(target: self, action: #selector(openFile(_:)))
            self.messageView?.addGestureRecognizer(tapGesture)
        }
        return setup
    }
}