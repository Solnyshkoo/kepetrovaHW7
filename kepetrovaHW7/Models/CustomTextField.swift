//
//  CustomTextField.swift
//  kepetrovaHW7
//
//  Created by Ksenia Petrova on 30.01.2022.
//

import Foundation
import UIKit

class CustomTextField: UITextField {
    init(text: String, frame: CGRect = .zero) {
        super.init(frame: frame)
        backgroundColor = UIColor.systemGray3
        textColor = UIColor.black
        placeholder = text
        layer.cornerRadius = 10
        clipsToBounds = false
        font = UIFont.systemFont(ofSize: 15)
        borderStyle = UITextField.BorderStyle.roundedRect
        autocorrectionType = UITextAutocorrectionType.yes
        keyboardType = UIKeyboardType.default
        returnKeyType = UIReturnKeyType.done
        clearButtonMode =
            UITextField.ViewMode.whileEditing
        contentVerticalAlignment =
            UIControl.ContentVerticalAlignment.center
        
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
