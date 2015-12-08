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
        case Limit16 = 16
    }
    
    // MARK: outlets
    @IBOutlet weak var charLimitPopupButton: NSPopUpButton!
    @IBOutlet weak var appendNumberCheckButton: NSButton!
    @IBOutlet weak var replacePrefixCheckButton: NSButton!
    
    // MARK: lifeCycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let defaultsDict = MpcUserDefaults.getImmutableDefsFile()
        if (defaultsDict.keys.count == 0) {
            MpcUserDefaults.setUpDefaultValues()
        }
        
        setUpView()
    }
    
    // MARK: setUpView
    func setUpView() {
        
        let charLimit = MpcUserDefaults.valueForKey(DEFS_KEY_MAX_CHARACTER_COUNT).integerValue
        
        if (charLimit != nil) {
            
            //ToDo: figure out how to get the int back into the ENUM Value without getting error: 'fatal error: unexpectedly found nil while unwrapping an Optional value'
            // it crashes even though the value is not nil
            
            switch charLimit {
            case 5000:
                charLimitPopupButton.selectItemAtIndex(0)
            case 8:
                charLimitPopupButton.selectItemAtIndex(1)
            case 16:
                charLimitPopupButton.selectItemAtIndex(2)
            default:
                charLimitPopupButton.selectItemAtIndex(0)
            }
        }
        
        appendNumberCheckButton.state  = MpcUserDefaults.valueForKey(DEFS_KEY_APPEND_NUMBER_TO_FILE_NAME).integerValue
        replacePrefixCheckButton.state = MpcUserDefaults.valueForKey(DEFS_KEY_REPLACE_EXISTING_PREFIX).integerValue
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
}
