//
//  CustomButtons.swift
//  kepetrovaHW7
//
//  Created by Ksenia Petrova on 30.01.2022.
//

import Foundation
import UIKit

class CustomButtons: UIButton {
    init(backColor: UIColor, textColor: UIColor, text: String, frame: CGRect = .zero) {
        super.init(frame: frame)
        setTitle(text, for: .normal)
        self.backgroundColor = backColor
        self.titleLabel?.textColor = textColor
        self.layer.cornerRadius = 15
        active(status: false)
    }

    func active(status: Bool) {
        if status {
            setTitleColor(.white, for: .normal)
            isEnabled = true
        } else {
            setTitleColor(.systemGray, for: .disabled)
            isEnabled = false
        }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
