//
//  exportOptionsVC.swift
//  mpc-audio
//
//  Created by Carl  on 07/12/2015.
//  Copyright © 2015 Carl Taylor. All rights reserved.
//

import Cocoa

class exportOptionsVC: NSViewController {
    
    enum CharacterLimit: Int {
        case limitNone = 5000
        case limit8 = 8
        case limit12 = 12
        case limit16 = 16
    }
    
    // MARK: outlets
    @IBOutlet weak var charLimitPopupButton: NSPopUpButton!
    @IBOutlet weak var appendNumberCheckButton: NSButton!
    @IBOutlet weak var replacePrefixCheckButton: NSButton!
    @IBOutlet weak var convertSamplesCheckButton: NSButton!
    
    // MARK: lifeCycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        MpcUserDefaults.setUpDefaultValuesIfPlistMissing()
        setUpView()
    }
    
    // MARK: setUpView
    func setUpView() {
        
        if let charLimitNumber = MpcUserDefaults.value(forKey: DEFS_KEY_MAX_CHARACTER_COUNT) as? NSNumber {
            switch charLimitNumber.intValue {
            case 5000:
                charLimitPopupButton.selectItem(at: 0)
            case 8:
                charLimitPopupButton.selectItem(at: 1)
            case 12:
                charLimitPopupButton.selectItem(at: 2)
            case 16:
                charLimitPopupButton.selectItem(at: 3)
            default:
                charLimitPopupButton.selectItem(at: 0)
            }
        }
        
        appendNumberCheckButton.state   = NSControl.StateValue(rawValue: (MpcUserDefaults.value(forKey: DEFS_KEY_APPEND_NUMBER_TO_FILE_NAME) as AnyObject).integerValue!)
        replacePrefixCheckButton.state  = NSControl.StateValue(rawValue: (MpcUserDefaults.value(forKey: DEFS_KEY_REPLACE_EXISTING_PREFIX) as AnyObject).integerValue!)
        convertSamplesCheckButton.state = NSControl.StateValue(rawValue: (MpcUserDefaults.value(forKey: DEFS_KEY_CONVERT_SAMPLES) as AnyObject).integerValue!)
    }
    
    // MARK: userActions
    @IBAction func charLimitValueChanged(_ button: NSPopUpButton) {
        
        var maxCharCount:CharacterLimit = CharacterLimit.limitNone
        
        switch button.indexOfSelectedItem {
        case 0:
            maxCharCount = CharacterLimit.limitNone
        case 1:
            maxCharCount = CharacterLimit.limit8
        case 2:
            maxCharCount = CharacterLimit.limit12
        case 3:
            maxCharCount = CharacterLimit.limit16
        default:
            NSException(name: NSExceptionName(rawValue: "** Illegal State **"), reason: "case not handled in charLimitPopUpButton", userInfo: nil).raise()
        }
        
        MpcUserDefaults.setValue(maxCharCount.rawValue, forKey: DEFS_KEY_MAX_CHARACTER_COUNT)
    }
    
    @IBAction func appendNumberPressed(_ button: NSButton) {
        MpcUserDefaults.setValue(button.state, forKey: DEFS_KEY_APPEND_NUMBER_TO_FILE_NAME)
    }
    
    @IBAction func replacePrefixPressed(_ button: NSButton) {
        MpcUserDefaults.setValue(button.state, forKey: DEFS_KEY_REPLACE_EXISTING_PREFIX)
    }
    
    @IBAction func convertSamplesPressed(_ button: NSButton) {
         MpcUserDefaults.setValue(button.state, forKey: DEFS_KEY_CONVERT_SAMPLES)
    }    
}
