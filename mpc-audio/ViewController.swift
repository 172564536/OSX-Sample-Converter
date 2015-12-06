//
//  ViewController.swift
//  mpc-audio
//
//  Created by Carl  on 05/12/2015.
//  Copyright © 2015 Carl Taylor. All rights reserved.
//

import Cocoa

class ViewController: NSViewController {
    
    // MARK: Outlets
    @IBOutlet weak var convertAudioButton: NSButton!
    
    // MARK: Ivars
    var selectedAudioFileUrls = []
    
    // MARK: LifeCycle
    override func viewDidLoad() {
        super.viewDidLoad()
        hideConvertAudioButton(true)
    }
    
    override var representedObject: AnyObject? {
        didSet {
            // Update the view, if already loaded.
        }
    }
    
    // MARK: UserActions
    @IBAction func selectFilesPressed(button: NSButton) {
     
        let filePicker: NSOpenPanel = NSOpenPanel()
        filePicker.allowsMultipleSelection = true
        filePicker.canChooseFiles = true
        filePicker.canChooseDirectories = false
        filePicker.runModal()
        
        selectedAudioFileUrls = filePicker.URLs
        if (selectedAudioFileUrls.count > 0) {
            hideConvertAudioButton(false)
        } else {
            hideConvertAudioButton(true)
        }
    }
    
    @IBAction func convertAudioPressed(button: NSButton) {
       hideConvertAudioButton(true)
        convertSelectedAudioFiles(selectedAudioFileUrls)
    }
    
    func hideConvertAudioButton(hidden: Bool) {
        self.convertAudioButton.hidden = hidden
    }
    
    func convertSelectedAudioFiles(fileUrls: NSArray) {
        
        let destinationFolder: NSURL = NSURL.init(fileURLWithPath: "///Users/carl/Desktop/converted")
        
        let conversionController: AudioFileConversionController = AudioFileConversionController()
        conversionController.convertAudioFilesFromUrls(fileUrls as! [NSArray], toDestinationFolder: destinationFolder) { () -> Void in
            print("DONE");            
        }
    }
}

