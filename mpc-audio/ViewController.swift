//
//  ViewController.swift
//  mpc-audio
//
//  Created by Carl  on 05/12/2015.
//  Copyright © 2015 Carl Taylor. All rights reserved.
//

import Cocoa

class ViewController: NSViewController, AudioFileConversionControllerDelegate {
    
    // MARK: constants
    let SEGUE_SERIAL_NUMBER = "serialNumberSeg"
    
    // MARK: outlets
    @IBOutlet weak var convertFilesButton: NSButton!
    
    @IBOutlet weak var selectedOutputFolderTextField: NSTextField!
    @IBOutlet weak var numberOfFilesSelectedTextField: NSTextField!
    @IBOutlet weak var fileNamePrefixTextField: NSTextField!
    @IBOutlet weak var authorisedEmaiTextField: NSTextField!
    
    @IBOutlet weak var progressIndicator: NSProgressIndicator!
    
    // MARK: ivars
    var selectedAudioFileUrls = [URL]()
    var selectedFolder: URL?
    var conversionController: AudioFileConversionController?
    var numberOfFilesSelectedToProcess: Int?
    
    // MARK: lifeCycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setUpView()
    }
    
    override func viewDidAppear() {
       let userRegistered = checkForRegisteredUser()
        if (userRegistered) {
            let userEmail = SerialNumberController.getAuthorisedUsersEmail()
            authorisedEmaiTextField.stringValue = "Authorised to: \(userEmail)"
        }
    }
    
    // MARK: checkForRegisteredUser
    func checkForRegisteredUser() -> Bool {
        if (!SerialNumberController.userHasAuthorisedApp()) {
            performSegue(withIdentifier: SEGUE_SERIAL_NUMBER, sender: self)
            return false
        } else {
            return true
        }
    }
    
    // MARK: setUpView
    func setUpView() {
        enableConvertAudioButton(false)
    }
    
    // MARK: userActions
    @IBAction func selectOutputFolderPressed(_ sender: NSButton) {
        
        let folderPicker: NSOpenPanel = NSOpenPanel()
        folderPicker.canCreateDirectories = true
        folderPicker.canChooseDirectories = true
        folderPicker.canChooseFiles = false;
        folderPicker.title = "Select Folder"
        folderPicker.showsHiddenFiles = false
        folderPicker.showsTagField = false
        folderPicker.begin(completionHandler: { (result) -> Void in
            if (result == NSFileHandlingPanelOKButton) {
                
                self.selectedFolder = folderPicker.url!
                self.selectedOutputFolderTextField.stringValue = self.selectedFolder!.absoluteString
                
                if (self.selectedFolder != nil && self.canShowConvertAudioButton()) {
                    self.enableConvertAudioButton(true)
                }
            }
        })
    }
    
    @IBAction func selectFilesPressed(_ button: NSButton) {
        
        let filePicker: NSOpenPanel = NSOpenPanel()
        filePicker.allowedFileTypes = ["wav", "aif", "aiff"]
        filePicker.allowsMultipleSelection = true
        filePicker.canChooseFiles = true
        filePicker.title = "Select Files"
        filePicker.canChooseDirectories = false
        filePicker.begin { (result) -> Void in
            if (result == NSFileHandlingPanelOKButton) {
                
                self.selectedAudioFileUrls = filePicker.urls
                self.numberOfFilesSelectedTextField.stringValue = "\(self.selectedAudioFileUrls.count)"
                if (self.selectedAudioFileUrls.count > 0 && self.canShowConvertAudioButton()) {
                    self.enableConvertAudioButton(true)
                } else {
                    self.enableConvertAudioButton(false)
                }
            }
        }
    }
    
    @IBAction func convertFilesPressed(_ sender: NSButton) {
        
        enableConvertAudioButton(false)
        let exportPrefix = fileNamePrefixTextField.stringValue
        
        MpcUserDefaults.setUpDefaultValuesIfPlistMissing()
        
        let exportConfig = ExportConfig()
        exportConfig.build(fromDefaults: MpcUserDefaults.getImmutableDefsFile())
        exportConfig.exportPrefix = exportPrefix
        
        startConversionWithExportOptions(exportConfig)
    }
    
    // MARK: hide/show convert audio button
    func canShowConvertAudioButton() -> Bool {
        if (selectedFolder != nil && selectedAudioFileUrls.count > 0) {
            return true;
        } else {
            return false;
        }
    }
    
    func enableConvertAudioButton(_ enable: Bool) {
        self.convertFilesButton.isEnabled = enable
        if (enable == true) {
            self.convertFilesButton.isHidden = false;
        } else {
            self.convertFilesButton.isHidden = true;
        }
    }
    
    // MARK: AudioFileConversionController / Delegate
    func startConversionWithExportOptions(_ exportConfig: ExportConfig) {
        
        numberOfFilesSelectedToProcess = selectedAudioFileUrls.count
        startProgressIndicator()
        
        conversionController = AudioFileConversionController.init(audioFileUrls: selectedAudioFileUrls, destinationFolder: selectedFolder,  andExportOptionsConfig: exportConfig)
        conversionController?.delegate = self
        conversionController!.start()
    }
    
    func audioFileConversionControllerDidFinish(withReport report: String!) {
        stopProgressIndicator()
        enableConvertAudioButton(true)
        if (report != nil) {
            showAlertWithMesage(report)
        }
    }
    
    func audioFileConversionControllerDidReportProgress() {
        incrementProgressIndicator()
    }
    
    func audioFileConversionControllerDidEncounterFileClash(forFile fileName: String!) -> FileClashDecision {
        
        let alert = NSAlert()
        alert.alertStyle = NSAlertStyle.informational
        alert.messageText = "Existing file found at location:\n\(fileName)"
        // These are applied in reverse order to how they appear on screen
        alert.addButton(withTitle: FILE_CLASH_BUTTON_TITLE_DELETE_APPLY_TO_ALL)
        alert.addButton(withTitle: FILE_CLASH_BUTTON_TITLE_DELETE)
        alert.addButton(withTitle: FILE_CLASH_BUTTON_TITLE_SKIP_APPLY_TO_ALL)
        alert.addButton(withTitle: FILE_CLASH_BUTTON_TITLE_SKIP)
        alert.addButton(withTitle: FILE_CLASH_BUTTON_TITLE_ABORT)
        
        let responseTag: NSModalResponse = alert.runModal()
        
        var decision: FileClashDecision = FileClashDecision.FILE_CLASH_ABORT
        
        switch responseTag {
        case 1000:
            decision = FileClashDecision.FILE_CLASH_DELETE_APPLY_TO_ALL;
        case 1001:
            decision = FileClashDecision.FILE_CLASH_DELETE;
        case 1002:
            decision = FileClashDecision.FILE_CLASH_SKIP_APPLY_TO_ALL;
        case 1003:
            decision = FileClashDecision.FILE_CLASH_SKIP;
        case 1004:
            decision = FileClashDecision.FILE_CLASH_ABORT;
        default:
            NSException(name: NSExceptionName(rawValue: "** Illegal State **"), reason: "case not handled in existing file found alert resonse", userInfo: nil).raise()
        }
        return decision
    }
    
    // MARK: ProgressIndicator
    func startProgressIndicator() {
        progressIndicator.maxValue = Double(selectedAudioFileUrls.count)
        progressIndicator.startAnimation(self)
    }
    
    func incrementProgressIndicator() {
        progressIndicator.increment(by: 1)
    }
    
    func stopProgressIndicator() {
        progressIndicator.stopAnimation(self)
        progressIndicator.increment(by: -Double(numberOfFilesSelectedToProcess!))
    }
    
    // MARK: Alert
    func showAlertWithMesage(_ message: String) {
        let alert = NSAlert()
        alert.alertStyle = NSAlertStyle.informational
        alert.addButton(withTitle: "Ok")
        alert.messageText = message
        alert.runModal()
    }
    
    
}

