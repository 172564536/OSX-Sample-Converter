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
    
    @IBAction func authoriseButtonPressed(_ sender: AnyObject) {
        let serialNumber = serialNumberTextField.stringValue
        if (serialNumber.characters.count > 0) {
            AttemptAuthorisationForSerial(serialNumber)
        } else {
            showMessage("Please enter your serial number")
        }
    }
    
    func AttemptAuthorisationForSerial(_ serial: String) {
        
        authoriseButton.isEnabled = false
        serialNumberTextField.isEnabled = false
        progress.isHidden = false
        progress.startAnimation(self)
        weak var weakSelf = self
        
        SerialNumberController.attemptAuthorisation(forKey: serial) { (userMessage, authSuccess) -> Void in
            weakSelf?.progress.isHidden = true
            weakSelf?.progress.stopAnimation(weakSelf)
            
            if (authSuccess) {
                weakSelf!.showMessage(userMessage!)
                weakSelf!.dismissViewController(self)
            } else {
                weakSelf!.showMessage(userMessage!)
                weakSelf!.authoriseButton.isEnabled = true
                weakSelf?.serialNumberTextField.isEnabled = true
            }
        }
    }    

    func showMessage(_ message: String) {
        let alert = NSAlert()
        alert.alertStyle = NSAlertStyle.informational
        alert.messageText = message
        alert.addButton(withTitle: "Ok")
        alert.runModal()
    }
}
