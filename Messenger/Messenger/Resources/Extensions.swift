//
//  Extensions.swift
//  Messenger
//
//  Created by Jervy Umandap on 6/1/21.
//

import UIKit

extension UIView {
    public var width: CGFloat {
        return frame.size.width
    }
    
    public var height: CGFloat {
        return frame.size.height
    }
    
    public var top: CGFloat {
        return frame.origin.y
    }
    
    public var bottom: CGFloat {
        return frame.size.height + top
    }
    
    public var left: CGFloat {
        return frame.origin.x
    }
    
    public var right: CGFloat {
        return frame.size.width + left
    }
}

extension Notification.Name {
    /// User login notification.
    static let didLoginNotification = Notification.Name("didLogInNotification")
}
