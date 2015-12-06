//
//  ViewController.swift
//  mpc-audio
//
//  Created by Carl  on 05/12/2015.
//  Copyright © 2015 Carl Taylor. All rights reserved.
//

import Cocoa

class ViewController: NSViewController {
    
    // MARK: outlets
    @IBOutlet weak var convertAudioButton: NSButton!
    @IBOutlet weak var selectedOutputFolderTextField: NSTextField!
    
    // MARK: ivars
    var selectedAudioFileUrls = []
    var selectedFolder: NSURL?
    
    // MARK: lifeCycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setUpView()
    }
    
    override var representedObject: AnyObject? {
        didSet {
            // Update the view, if already loaded.
        }
    }
    
     // MARK: setUpView
    func setUpView() {
        hideConvertAudioButton(true)
        selectedOutputFolderTextField.editable = false;
    }
    
    // MARK: userActions
    @IBAction func selectOutputFolderPressed(sender: NSButton) {
        
        let folderPicker: NSOpenPanel = NSOpenPanel()
        folderPicker.canCreateDirectories = true
        folderPicker.canChooseDirectories = true
        folderPicker.title = "Select Folder"
        folderPicker.showsHiddenFiles = false
        folderPicker.showsTagField = false
        folderPicker.beginWithCompletionHandler({ (result) -> Void in
            if (result == NSFileHandlingPanelOKButton) {
                
                self.selectedFolder = folderPicker.URL!
                self.selectedOutputFolderTextField.stringValue = self.selectedFolder!.absoluteString
                
                if (self.selectedFolder != nil && self.canShowConvertAudioButton()) {
                    self.hideConvertAudioButton(false)
                }
            }
        })
    }
    
    @IBAction func selectFilesPressed(button: NSButton) {
        
        let filePicker: NSOpenPanel = NSOpenPanel()
        filePicker.allowsMultipleSelection = true
        filePicker.canChooseFiles = true
        filePicker.title = "Select Files"
        filePicker.canChooseDirectories = false
        filePicker.runModal()
        
        selectedAudioFileUrls = filePicker.URLs
        
        if (selectedAudioFileUrls.count > 0 && canShowConvertAudioButton()) {
            hideConvertAudioButton(false)
        } else {
            hideConvertAudioButton(true)
        }
    }
    
    @IBAction func convertAudioPressed(button: NSButton) {
        
        hideConvertAudioButton(true)
        
        let conversionController: AudioFileConversionController = AudioFileConversionController()
        conversionController.convertAudioFilesFromUrls(selectedAudioFileUrls as! [NSArray], toDestinationFolder: selectedFolder) { () -> Void in
            print("DONE");
        }
    }
    
    // MARK: hide/show convert audio button
    func canShowConvertAudioButton() -> Bool {
        if (selectedFolder != nil && selectedAudioFileUrls.count > 0) {
            return true;
        } else {
            return false;
        }
    }
    
    func hideConvertAudioButton(hidden: Bool) {
        self.convertAudioButton.hidden = hidden
    }
}

