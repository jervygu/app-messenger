//
//  ProfileViewModel.swift
//  Messenger
//
//  Created by Jervy Umandap on 6/15/21.
//

import UIKit


enum ProfileViewModelType {
    case logout, legalPolicies, help
}

struct ProfileViewModel {
    let viewModelType: ProfileViewModelType
    let title: String
    let iconName: String
    let color: UIColor
    let handler: (() -> Void)?
}
