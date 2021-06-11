//
//  Extensions.swift
//  Messenger
//
//  Created by Jervy Umandap on 6/1/21.
//

import UIKit

extension UIView {
    public var width: CGFloat {
        return self.frame.size.width
    }
    
    public var height: CGFloat {
        return self.frame.size.height
    }
    
    public var top: CGFloat {
        return self.frame.origin.y
    }
    
    public var bottom: CGFloat {
        return self.frame.size.height + top
    }
    
    public var left: CGFloat {
        return self.frame.origin.x
    }
    
    public var right: CGFloat {
        return self.frame.size.width + left
    }
}

extension Notification.Name {
    /// User login notification.
    static let didLoginNotification = Notification.Name("didLogInNotification")
}
