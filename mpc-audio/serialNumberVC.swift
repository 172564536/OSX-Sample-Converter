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
    
    @IBAction func authoriseButtonPressed(sender: AnyObject) {
        var serialNumber = serialNumberTextField.stringValue
        if (serialNumber.characters.count > 0) {
//            serialNumber = "965D1A94-33564923-8BD47293-4093BFEF"
            AttemptAuthorisationForSerial(serialNumber)
        } else {
            showMessage("Please enter your serial number")
        }
    }
    
    func AttemptAuthorisationForSerial(serial: String) {
            SerialNumberController.attemptAuthorisationForKey(serial) { (userMessage, authSuccess) -> Void in
                if (authSuccess) {
                    self.showMessage(userMessage)
                    self.dismissViewController(self)
                } else {
                    self.showMessage(userMessage)
                }
        }
    }
    
    func showMessage(message: String) {
        let alert = NSAlert()
        alert.alertStyle = NSAlertStyle.InformationalAlertStyle
        alert.messageText = message
        alert.addButtonWithTitle("Ok")
        alert.runModal()
    }
}
