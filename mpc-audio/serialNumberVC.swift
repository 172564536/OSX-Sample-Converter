//
//  serialNumberVC.swift
//  mpc-audio
//
//  Created by Carl  on 11/12/2015.
//  Copyright © 2015 Carl Taylor. All rights reserved.
//

import Cocoa

class serialNumberVC: NSViewController {
    
    @IBOutlet weak var serialNumberTextField: NSTextField!
    @IBOutlet weak var authoriseButton: NSButton!
    @IBOutlet weak var progress: NSProgressIndicator!
    
    @IBAction func authoriseButtonPressed(sender: AnyObject) {
        let serialNumber = serialNumberTextField.stringValue
        if (serialNumber.characters.count > 0) {
            //            serialNumber = "965D1A94-33564923-8BD47293-4093BFEF"
            AttemptAuthorisationForSerial(serialNumber)
        } else {
            showMessage("Please enter your serial number")
        }
    }
    
    func AttemptAuthorisationForSerial(serial: String) {
        
        authoriseButton.enabled = false
        progress.hidden = false
        progress.startAnimation(self)
        weak var weakSelf = self
        
        SerialNumberController.attemptAuthorisationForKey(serial) { (userMessage, authSuccess) -> Void in
            weakSelf?.progress.hidden = true
            weakSelf?.progress.stopAnimation(weakSelf)
            
            if (authSuccess) {
                weakSelf!.showMessage(userMessage)
                weakSelf!.dismissViewController(self)
            } else {
                weakSelf!.showMessage(userMessage)
                weakSelf!.authoriseButton.enabled = true
            }
        }
    }
    
    // MARK: Alert
    func showMessage(message: String) {
        let alert = NSAlert()
        alert.alertStyle = NSAlertStyle.InformationalAlertStyle
        alert.messageText = message
        alert.addButtonWithTitle("Ok")
        alert.runModal()
    }
}
