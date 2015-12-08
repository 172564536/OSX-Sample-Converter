//
//  ViewController.swift
//  mpc-audio
//
//  Created by Carl  on 05/12/2015.
//  Copyright © 2015 Carl Taylor. All rights reserved.
//

import Cocoa

class ViewController: NSViewController, AudioFileConversionControllerDelegate {
    
    // MARK: outlets
    @IBOutlet weak var convertFilesButton: NSButton!
    
    @IBOutlet weak var selectedOutputFolderTextField: NSTextField!
    @IBOutlet weak var numberOfFilesSelectedTextField: NSTextField!
    @IBOutlet weak var fileNamePrefixTextField: NSTextField!
    
    @IBOutlet weak var progressIndicator: NSProgressIndicator!
    
    // MARK: ivars
    var selectedAudioFileUrls = []
    var selectedFolder: NSURL?
    var conversionController: AudioFileConversionController?
    var numberOfFilesSelectedToProcess: Int?
    
    // MARK: lifeCycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setUpView()
    }
    
    // MARK: setUpView
    func setUpView() {
        enableConvertAudioButton(false)
        selectedOutputFolderTextField.editable = false;
        numberOfFilesSelectedTextField.editable = false;
    }
    
    // MARK: userActions
    @IBAction func selectOutputFolderPressed(sender: NSButton) {
        
        let folderPicker: NSOpenPanel = NSOpenPanel()
        folderPicker.canCreateDirectories = true
        folderPicker.canChooseDirectories = true
        folderPicker.canChooseFiles = false;
        folderPicker.title = "Select Folder"
        folderPicker.showsHiddenFiles = false
        folderPicker.showsTagField = false
        folderPicker.beginWithCompletionHandler({ (result) -> Void in
            if (result == NSFileHandlingPanelOKButton) {
                
                self.selectedFolder = folderPicker.URL!
                self.selectedOutputFolderTextField.stringValue = self.selectedFolder!.absoluteString
                
                if (self.selectedFolder != nil && self.canShowConvertAudioButton()) {
                    self.enableConvertAudioButton(true)
                }
            }
        })
    }
    
    @IBAction func selectFilesPressed(button: NSButton) {
        
        let filePicker: NSOpenPanel = NSOpenPanel()
        filePicker.allowedFileTypes = ["wav", "aif"]
        filePicker.allowsMultipleSelection = true
        filePicker.canChooseFiles = true
        filePicker.title = "Select Files"
        filePicker.canChooseDirectories = false
        filePicker.beginWithCompletionHandler { (result) -> Void in
            if (result == NSFileHandlingPanelOKButton) {
                
                self.selectedAudioFileUrls = filePicker.URLs
                self.numberOfFilesSelectedTextField.stringValue = "Files selected: \(self.selectedAudioFileUrls.count)"
                if (self.selectedAudioFileUrls.count > 0 && self.canShowConvertAudioButton()) {
                    self.enableConvertAudioButton(true)
                } else {
                    self.enableConvertAudioButton(true)
                }
            }
        }
    }
    
    @IBAction func convertFilesPressed(sender: NSButton) {
        
        enableConvertAudioButton(false)
        let exportPrefix = fileNamePrefixTextField.stringValue
        
        MpcUserDefaults.setUpDefaultValuesIfPlistMissing()
        
        let exportConfig = ExportConfig()
        exportConfig.buildFromDefaults(MpcUserDefaults.getImmutableDefsFile())
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
    
    func enableConvertAudioButton(enable: Bool) {
        self.convertFilesButton.enabled = enable
    }
    
    // MARK: AudioFileConversionController / Delegate
    func startConversionWithExportOptions(exportConfig: ExportConfig) {
        
        numberOfFilesSelectedToProcess = selectedAudioFileUrls.count
        startProgressIndicator()
        
        conversionController = AudioFileConversionController.init(audioFileUrls: selectedAudioFileUrls as! [NSArray], destinationFolder: selectedFolder,  andExportOptionsConfig: exportConfig)
        conversionController?.delegate = self
        conversionController!.start()
    }
    
    func audioFileConversionControllerDidFinish() {
        stopProgressIndicator()
        enableConvertAudioButton(true)
    }
    
    func audioFileConversionControllerDidReportProgress() {
        incrementProgressIndicator()
    }
    
    // MARK: ProgressIndicator
    func startProgressIndicator() {
        progressIndicator.maxValue = Double(selectedAudioFileUrls.count)
        progressIndicator.startAnimation(self)
    }
    
    func incrementProgressIndicator() {
        progressIndicator.incrementBy(1)
    }
    
    func stopProgressIndicator() {
        progressIndicator.stopAnimation(self)
        progressIndicator.incrementBy(-Double(numberOfFilesSelectedToProcess!))
    }
}

