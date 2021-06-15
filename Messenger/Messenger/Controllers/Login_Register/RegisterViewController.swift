//
//  RegisterViewController.swift
//  Messenger
//
//  Created by Jervy Umandap on 6/1/21.
//

import UIKit
import Firebase
import JGProgressHUD

class RegisterViewController: UIViewController {
    
    private let scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.clipsToBounds = true
        return scrollView
    }()
    
    private let container: UIView = {
        let view = UIView()
        return view
    }()
    
    private let dividerView: UIView = {
        let view = UIView()
        return view
    }()
    
    private let dividerView2: UIView = {
        let view = UIView()
        return view
    }()
    
    private let dividerView3: UIView = {
        let view = UIView()
        return view
    }()
    
    private let imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(systemName: "person.circle.fill")
        imageView.tintColor = .secondaryLabel
        imageView.contentMode = .scaleAspectFit
        imageView.layer.masksToBounds = true
        imageView.layer.borderWidth = 2.0
        imageView.layer.borderColor = UIColor.secondaryLabel.cgColor
        
        imageView.clipsToBounds = true
        return imageView
    }()
    
    private let emailTF: UITextField = {
        let textField = UITextField()
        textField.autocapitalizationType = .none
        textField.autocorrectionType = .no
        textField.returnKeyType = .continue
        textField.placeholder = "Email"
        textField.textColor = .label
        textField.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 5, height: 0))
        textField.leftViewMode = .always
        
        return textField
    }()
    
    private let passwordTF: UITextField = {
        let textField = UITextField()
        textField.autocapitalizationType = .none
        textField.autocorrectionType = .no
        textField.returnKeyType = .done
        textField.placeholder = "Password"
        textField.textColor = .label
        textField.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 5, height: 0))
        textField.leftViewMode = .always
        textField.isSecureTextEntry = true
        return textField
    }()
    
    private let firstnameTF: UITextField = {
        let textField = UITextField()
        textField.autocapitalizationType = .none
        textField.autocorrectionType = .no
        textField.returnKeyType = .continue
        textField.placeholder = "First name"
        textField.textColor = .label
        textField.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 5, height: 0))
        textField.leftViewMode = .always
        return textField
    }()
    
    private let lastnameTF: UITextField = {
        let textField = UITextField()
        textField.autocapitalizationType = .none
        textField.autocorrectionType = .no
        textField.returnKeyType = .continue
        textField.placeholder = "Last name"
        textField.textColor = .label
        textField.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 5, height: 0))
        textField.leftViewMode = .always
        return textField
    }()
    
    
    
    private let registerButton: UIButton = {
        let button = UIButton()
        button.layer.cornerRadius = 15
        button.setTitle("REGISTER", for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 15, weight: .light)
        button.setTitleColor(.white, for: .normal)
        return button
    }()
    
    private let spinner = JGProgressHUD(style: .dark)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Create Account"
        view.backgroundColor = .systemBackground
        
        // Add subviews
        view.addSubview(scrollView)
        scrollView.addSubview(container)
        container.addSubview(imageView)
        container.addSubview(dividerView)
//        dividerView.tintColor = .black
        container.addSubview(emailTF)
        container.addSubview(dividerView2)
        container.addSubview(passwordTF)
        container.addSubview(dividerView3)
        container.addSubview(firstnameTF)
        container.addSubview(lastnameTF)
        container.addSubview(registerButton)
        
        dividerView.backgroundColor = .secondarySystemFill
        dividerView2.backgroundColor = .secondarySystemFill
        dividerView3.backgroundColor = .secondarySystemFill
        registerButton.backgroundColor = .systemGreen
        
        registerButton.addTarget(self, action: #selector(didTapRegister), for: .touchUpInside)
        
        emailTF.delegate = self
        passwordTF.delegate = self
        firstnameTF.delegate = self
        lastnameTF.delegate = self
        
        scrollView.isUserInteractionEnabled = true
        
        let gesture = UITapGestureRecognizer(target: self, action: #selector(didTapChangeProfilePic))
        gesture.numberOfTouchesRequired = 1
        gesture.numberOfTapsRequired = 1
        imageView.isUserInteractionEnabled = true
        imageView.addGestureRecognizer(gesture)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        scrollView.frame = view.bounds
        
        let containerHeight = view.height*0.90
        container.frame = CGRect(
            x: 20,
            y: scrollView.height-containerHeight-view.safeAreaInsets.top-view.safeAreaInsets.bottom,
            width: view.width-40,
            height: containerHeight)
//        container.backgroundColor = .systemPink
        
        let imageSize = container.width/2.5
        imageView.frame = CGRect(
            x: (container.width-imageSize)/2,
            y: 100,
            width: imageSize,
            height: imageSize)
        imageView.layer.cornerRadius = imageSize/2
//        imageView.backgroundColor = .systemRed
        
        firstnameTF.frame = CGRect(
            x: 0,
            y: imageView.bottom+10,
            width: container.width,
            height: 40)
//        emailTF.backgroundColor = .systemGreen
        
        dividerView.frame = CGRect(
            x: -2,
            y: firstnameTF.bottom,
            width: view.width-36,
            height: 1)
//        dividerView.backgroundColor = .systemPink
        
        lastnameTF.frame = CGRect(
            x: 0,
            y: dividerView.bottom,
            width: container.width,
            height: 40)
//        passwordTF.backgroundColor = .systemTeal
        
        dividerView2.frame = CGRect(
            x: -2,
            y: lastnameTF.bottom,
            width: view.width-36,
            height: 1)
//        dividerView2.backgroundColor = .systemPink
        
        emailTF.frame = CGRect(
            x: 0,
            y: dividerView2.bottom,
            width: container.width,
            height: 40)
//        firstnameTF.backgroundColor = .systemGreen
        
        dividerView3.frame = CGRect(
            x: -2,
            y: emailTF.bottom,
            width: view.width-36,
            height: 1)
//        dividerView3.backgroundColor = .systemPink
        
        passwordTF.frame = CGRect(
            x: 0,
            y: dividerView3.bottom,
            width: container.width,
            height: 40)
//        lastnameTF.backgroundColor = .systemGreen
        
        registerButton.frame = CGRect(
            x: 0,
            y: passwordTF.bottom,
            width: container.width,
            height: 40)
    }
    
    @objc private func didTapChangeProfilePic() {
        print("Change pic tapped")
        presentPhotoActionSheet()
    }
    
    func alertUserRegistrationError(message: String = "Please enter all information to create a new account.") {
        let alert = UIAlertController(
            title: "Invalid Registration",
            message: message,
            preferredStyle: .alert)
        
        alert.addAction(
            UIAlertAction(
                title: "Dismiss",
                style: .cancel,
                handler: nil))
        
        present(alert, animated: true, completion: nil)
    }
    
    @objc private func didTapRegister() {
        firstnameTF.resignFirstResponder()
        lastnameTF.resignFirstResponder()
        emailTF.resignFirstResponder()
        passwordTF.resignFirstResponder()
        
        guard let firstName = firstnameTF.text,
              let lastName = lastnameTF.text,
              let email = emailTF.text,
              let password = passwordTF.text,
              !firstName.isEmpty,
              !lastName.isEmpty,
              !email.isEmpty,
              !password.isEmpty, password.count >= 6 else {
            alertUserRegistrationError()
            return
        }
        
        spinner.show(in: view)
        // Firebase Register
        
        DatabaseManager.shared.userExists(withEmail: email) { [weak self] (exists) in
            guard let strongSelf = self else {
                return
            }
            
            DispatchQueue.main.async {
                strongSelf.spinner.dismiss()
            }
            
            guard !exists else {
                // user already exists
                strongSelf.alertUserRegistrationError(message: "The email address is already in use by another account.")
                
                return
            }
            
            Auth.auth().createUser(withEmail: email, password: password) { (authResult, error) in
                // Cache user data
                UserDefaults.standard.setValue(email, forKey: "email")
                UserDefaults.standard.setValue("\(firstName) \(lastName)", forKey: "name")
                
                guard authResult != nil, error == nil else {
                    print("\(String(describing: error!.localizedDescription))")
                    return
                }
                // success
                
                let messengerUser = MessengerUser(firstName: firstName, lastName: lastName, emailAddress: email)
                
                /// Inserts new user to database
                DatabaseManager.shared.insertUser(
                    withUser: messengerUser, completion: { success in
                        
                        // upload image
                        guard let image = self?.imageView.image,
                              let data = image.pngData() else {
                            return
                        }
                        
                        let fileName = messengerUser.profilePictureFileName
                        StorageManager.shared.uploadProfilePicture(
                            withData: data,
                            withfileName: fileName) { (result) in
                            
                            switch result {
                            case .success(let downloadUrl):
                                UserDefaults.standard.setValue(downloadUrl, forKey: "profile_picture_url")
                                print("downloadUrl: - \(downloadUrl)")
                            case .failure(let error):
                                print("Storage manager error: - \(error.localizedDescription)")
                            }
                        }
                        
                    })
                
                strongSelf.navigationController?.dismiss(animated: true, completion: nil)
            }
        }
    }
    
    
    
}

extension RegisterViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        
        if textField == firstnameTF {
            lastnameTF.becomeFirstResponder()
        } else if textField == lastnameTF {
            emailTF.becomeFirstResponder()
        } else if textField == emailTF {
            passwordTF.becomeFirstResponder()
        } else if textField == passwordTF {
            didTapRegister()
        }
        
        return true
    }
}

extension RegisterViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    func presentPhotoActionSheet() {
        let actionSheet = UIAlertController(
            title: "Profile Picture",
            message: "How would you like to select a picture?",
            preferredStyle: .actionSheet)
        
        actionSheet.addAction(UIAlertAction(
                                title: "Cancel",
                                style: .cancel,
                                handler: nil))
        
        actionSheet.addAction(UIAlertAction(
                                title: "Take Photo",
                                style: .default,
                                handler: { [weak self] (_) in
                                    self?.presentCamera()
                                }))
        
        actionSheet.addAction(UIAlertAction(
                                title: "Choose photo",
                                style: .default,
                                handler: { [weak self] (_) in
                                    self?.presentPhotoPicker()
                                }))
        
        present(actionSheet, animated: true, completion: nil)
    }
    
    func presentCamera() {
        let vc = UIImagePickerController()
        vc.sourceType = .camera
        vc.delegate = self
        vc.allowsEditing = true
        present(vc, animated: true, completion: nil)
    }
    
    func presentPhotoPicker() {
        let vc = UIImagePickerController()
        vc.sourceType = .photoLibrary
        vc.delegate = self
        vc.allowsEditing = true
        present(vc, animated: true, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true, completion: nil)
        print(info)
        
        
        guard let selectedImage = info[UIImagePickerController.InfoKey.editedImage] as? UIImage else {
            return
        }
        
        self.imageView.image = selectedImage
            
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
}

/// 30:30
