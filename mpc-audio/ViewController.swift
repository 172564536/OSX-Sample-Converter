//
//  ViewController.swift
//  mpc-audio
//
//  Created by Carl  on 05/12/2015.
//  Copyright © 2015 Carl Taylor. All rights reserved.
//

import Cocoa


class ViewController: NSViewController, AudioFileConversionControllerDelegate, AudioFileModelFactoryDelegate {
        
    // MARK: outlets
    @IBOutlet weak var convertFilesButton: NSButton!
    @IBOutlet weak var exportOptionButton: NSButton!
    @IBOutlet weak var outputFolderButton: NSButton!
    @IBOutlet weak var filesFolderButton: NSButton!
    
    @IBOutlet weak var selectedOutputFolderTextField: NSTextField!
    @IBOutlet weak var numberOfFilesSelectedTextField: NSTextField!
    @IBOutlet weak var fileNamePrefixTextField: NSTextField!
    
    @IBOutlet weak var progressIndicator: NSProgressIndicator!
    
    // MARK: ivars
    var selectedFileUrls = [URL]()
    var selectedOutputFolder: URL?
    var selectedParentSourceFolder: URL?
    var conversionController: AudioFileConversionController?
    var numberOfFilesSelectedToProcess: Int?
    let audioModelFactory = AudioFileModelFactory()

    // MARK: lifeCycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setUpView()
        audioModelFactory.delegate = self
    }
    

    // MARK: checkForRegisteredUser
    func checkForRegisteredUser() -> Bool {
        return true
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
            if (result.rawValue == NSFileHandlingPanelOKButton) {
                
                self.selectedOutputFolder = folderPicker.url!

                var pathString = ""
                let paths = self.selectedOutputFolder!.pathComponents
                if (paths.count > 1) {
                    pathString = "\(paths[paths.count-2])\\\(paths.last!)"
                } else {
                    pathString = "\(paths.last)"
                }

                self.selectedOutputFolderTextField.stringValue = pathString
                
                if (self.selectedOutputFolder != nil && self.canShowConvertAudioButton()) {
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
        filePicker.canChooseDirectories = true
        filePicker.begin { (result) -> Void in
            if (result.rawValue == NSFileHandlingPanelOKButton) {
                self.selectedFileUrls = filePicker.urls
                if (filePicker.urls.count > 1) {
                    var components = filePicker.url?.pathComponents
                    components!.removeLast()
                    self.selectedParentSourceFolder = NSURL.fileURL(withPathComponents: components!)
                } else {
                    self.selectedParentSourceFolder = filePicker.url
                }

                self.numberOfFilesSelectedToProcess = self.audioModelFactory.countNumber(ofAudioFilesPresent: filePicker.urls).intValue
                self.numberOfFilesSelectedTextField.stringValue = "\(self.numberOfFilesSelectedToProcess!)"
                if (self.selectedFileUrls.count > 0 && self.canShowConvertAudioButton()) {
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
        if (selectedOutputFolder != nil && selectedFileUrls.count > 0) {
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

    // MARK: Show/hide Main Panel
    func hideMainPanel(hide: Bool) {
        selectedOutputFolderTextField.isHidden = hide
        numberOfFilesSelectedTextField.isHidden = hide
        fileNamePrefixTextField.isHidden = hide
        exportOptionButton.isHidden = hide
        outputFolderButton.isHidden = hide
        filesFolderButton.isHidden = hide
    }
    
    // MARK: AudioFileConversionController + AudioFileModelFactory / Delegate
    func startConversionWithExportOptions(_ exportConfig: ExportConfig) {

        let convertedModels = audioModelFactory.convertSourceUrls(selectedFileUrls, parentSourceFolder: selectedParentSourceFolder, parentDestinationFolder: selectedOutputFolder, exportConfig: exportConfig)
        startProgressIndicator()
        hideMainPanel(hide: true)

        conversionController = AudioFileConversionController.init(audioFileModels: convertedModels, andExportOptionsConfig: exportConfig)
        conversionController?.delegate = self
        conversionController!.start()
    }

    func audioFileModelFactoryDidError(_ errorDescription: String!) -> AudioFileModelFactoryErrorDecision {

        let alert = NSAlert()
        alert.alertStyle = NSAlert.Style.warning
        alert.messageText = errorDescription
        // These are applied in reverse order to how they appear on screen
        alert.addButton(withTitle: "Continue (ignore similar errors)")
        alert.addButton(withTitle: "Continue")
        alert.addButton(withTitle: "Abort").setAccessibilityFocused(true)

        let responseTag: NSApplication.ModalResponse = alert.runModal()

        var decision: AudioFileModelFactoryErrorDecision = AudioFileModelFactoryErrorDecision.ERROR_ABORT;

        switch responseTag.rawValue {
        case 1000:
            decision = AudioFileModelFactoryErrorDecision.ERROR_CONTINUE_FOR_ALL;
        case 1001:
            decision = AudioFileModelFactoryErrorDecision.ERROR_CONTINUE;
        case 1002:
            decision = AudioFileModelFactoryErrorDecision.ERROR_ABORT;
        default:
            NSException(name: NSExceptionName(rawValue: "** Illegal State **"), reason: "case not handled in modelFactory error found alert response", userInfo: nil).raise()
        }
        return decision;
    }

    func audioFileConversionControllerDidError(_ errorMessage: String!) {
        showAlertWithMessage(errorMessage)
    }

    func audioFileConversionControllerDidFinish(withReport report: String!) {
        stopProgressIndicator()
        enableConvertAudioButton(true)
        hideMainPanel(hide: false)
        if (report != nil) {
            showAlertWithMessage(report)
        }
    }
    
    func audioFileConversionControllerDidReportProgress() {
        incrementProgressIndicator()
    }
    
    func audioFileConversionControllerDidEncounterFileClash(forFile fileName: String!) -> FileClashDecision {
        
        let alert = NSAlert()
        alert.alertStyle = NSAlert.Style.informational
        alert.messageText = "Existing file found at location:\n\(String(describing: fileName!))"
        // These are applied in reverse order to how they appear on screen
        alert.addButton(withTitle: FILE_CLASH_BUTTON_TITLE_DELETE_APPLY_TO_ALL)
        alert.addButton(withTitle: FILE_CLASH_BUTTON_TITLE_DELETE)
        alert.addButton(withTitle: FILE_CLASH_BUTTON_TITLE_SKIP_APPLY_TO_ALL)
        alert.addButton(withTitle: FILE_CLASH_BUTTON_TITLE_SKIP)
        alert.addButton(withTitle: FILE_CLASH_BUTTON_TITLE_ABORT)
        
        let responseTag: NSApplication.ModalResponse = alert.runModal()
        
        var decision: FileClashDecision = FileClashDecision.FILE_CLASH_ABORT
        
        switch responseTag.rawValue {
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
            NSException(name: NSExceptionName(rawValue: "** Illegal State **"), reason: "case not handled in existing file found alert response", userInfo: nil).raise()
        }
        return decision
    }
    
    // MARK: ProgressIndicator
    func startProgressIndicator() {
        progressIndicator.maxValue = Double(numberOfFilesSelectedToProcess!)
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
    func showAlertWithMessage(_ message: String) {
        let alert = NSAlert()
        alert.alertStyle = NSAlert.Style.informational
        alert.addButton(withTitle: "Ok")
        alert.messageText = message
        alert.runModal()
    }
}

