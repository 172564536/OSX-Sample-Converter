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
        case LimitNone = 5000
        case Limit8 = 8
        case limit12 = 12
        case Limit16 = 16
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
        
        let charLimit = MpcUserDefaults.valueForKey(DEFS_KEY_MAX_CHARACTER_COUNT).integerValue
        
        if (charLimit != nil) {
            
            switch charLimit {
            case 5000:
                charLimitPopupButton.selectItemAtIndex(0)
            case 8:
                charLimitPopupButton.selectItemAtIndex(1)
            case 12:
                charLimitPopupButton.selectItemAtIndex(2)
            case 16:
                charLimitPopupButton.selectItemAtIndex(3)
            default:
                charLimitPopupButton.selectItemAtIndex(0)
            }
        }
        
        appendNumberCheckButton.state   = MpcUserDefaults.valueForKey(DEFS_KEY_APPEND_NUMBER_TO_FILE_NAME).integerValue
        replacePrefixCheckButton.state  = MpcUserDefaults.valueForKey(DEFS_KEY_REPLACE_EXISTING_PREFIX).integerValue
        convertSamplesCheckButton.state = MpcUserDefaults.valueForKey(DEFS_KEY_CONVERT_SAMPLES).integerValue
    }
    
    // MARK: userActions
    @IBAction func charLimitValueChanged(button: NSPopUpButton) {
        
        var maxCharCount:CharacterLimit = CharacterLimit.LimitNone
        
        switch button.indexOfSelectedItem {
        case 0:
            maxCharCount = CharacterLimit.LimitNone
        case 1:
            maxCharCount = CharacterLimit.Limit8
        case 2:
            maxCharCount = CharacterLimit.limit12
        case 3:
            maxCharCount = CharacterLimit.Limit16
        default:
            NSException(name: "** Illegal State **", reason: "case not handled in charLimitPopUpButton", userInfo: nil).raise()
        }
        
        MpcUserDefaults.setValue(maxCharCount.rawValue, forKey: DEFS_KEY_MAX_CHARACTER_COUNT)
    }
    
    @IBAction func appendNumberPressed(button: NSButton) {
        MpcUserDefaults.setValue(button.state, forKey: DEFS_KEY_APPEND_NUMBER_TO_FILE_NAME)
    }
    
    @IBAction func replacePrefixPressed(button: NSButton) {
        MpcUserDefaults.setValue(button.state, forKey: DEFS_KEY_REPLACE_EXISTING_PREFIX)
    }
    
    @IBAction func convertSamplesPressed(button: AnyObject) {
         MpcUserDefaults.setValue(button.state, forKey: DEFS_KEY_CONVERT_SAMPLES)
    }    
}
