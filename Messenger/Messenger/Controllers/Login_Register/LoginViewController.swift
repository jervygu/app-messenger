//
//  LoginViewController.swift
//  Messenger
//
//  Created by Jervy Umandap on 6/1/21.
//

import UIKit
import Firebase
import FBSDKLoginKit
import GoogleSignIn
import JGProgressHUD

class LoginViewController: UIViewController {
    
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
    
    private let imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(named: "logo")
        imageView.contentMode = .scaleAspectFit
        imageView.layer.masksToBounds = true
        imageView.clipsToBounds = true
        return imageView
    }()
    
    private let spinner = JGProgressHUD(style: .dark)
    
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
    
    private let loginButton: UIButton = {
        let button = UIButton()
        button.layer.cornerRadius = 15
        button.setTitle("LOG IN", for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 15, weight: .light)
        button.setTitleColor(.label, for: .normal)
        return button
    }()
    
    private let createAccountButton: UIButton = {
        let button = UIButton()
        button.layer.cornerRadius = 15
        button.setTitle("CREATE NEW ACCOUNT", for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 15, weight: .light)
        button.setTitleColor(.white, for: .normal)
        return button
    }()
    
    private let forgotPasswordButton: UIButton = {
        let button = UIButton()
        button.layer.cornerRadius = 15
        button.setTitle("FORGOTTEN PASSWORD", for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 15, weight: .light)
        button.setTitleColor(.label, for: .normal)
        return button
    }()
    
    private let fbLoginButton: FBLoginButton = {
        let button = FBLoginButton()
        button.permissions = ["public_profile", "email"]
        return button
    }()
    
    private let googleSignInButton = GIDSignInButton()
    
    private var loginObserver: NSObjectProtocol?

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Log In"
        view.backgroundColor = .systemBackground
        
        // Observer
        loginObserver = NotificationCenter.default.addObserver(
            forName: .didLoginNotification,
            object: nil,
            queue: .main) { [weak self] (notification) in
            guard let strongSelf = self else {
                return
            }
            
            strongSelf.navigationController?.dismiss(animated: true, completion: nil)
        }

//        navigationItem.rightBarButtonItem = UIBarButtonItem(
//            title: "Register",
//            style: .done,
//            target: self,
//            action: #selector(didTapRegister))
        
        // Add subviews
        view.addSubview(scrollView)
        scrollView.addSubview(container)
        container.addSubview(imageView)
        container.addSubview(dividerView)
        dividerView.tintColor = .black
        container.addSubview(emailTF)
        container.addSubview(passwordTF)
        container.addSubview(loginButton)
        container.addSubview(createAccountButton)
        container.addSubview(forgotPasswordButton)
        
        dividerView.backgroundColor = .secondarySystemFill
        loginButton.backgroundColor = .secondarySystemBackground
        createAccountButton.backgroundColor = .systemGreen
        
        loginButton.addTarget(self, action: #selector(didTapLogin), for: .touchUpInside)
        createAccountButton.addTarget(self, action: #selector(didTapRegister), for: .touchUpInside)
        
        forgotPasswordButton.addTarget(self, action: #selector(didTapForgot), for: .touchUpInside)
        
        emailTF.delegate = self
        passwordTF.delegate = self
        
        // FB Login
        container.addSubview(fbLoginButton)
        fbLoginButton.delegate = self
        
        // google signin
        GIDSignIn.sharedInstance()?.presentingViewController = self
        container.addSubview(googleSignInButton)
        
        
    }
    
    @objc func crashButtonTapped(_ sender: AnyObject) {
        fatalError()
    }
    
    deinit {
        if let observer = loginObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }
    
    @objc private func didTapRegister() {
        let vc = RegisterViewController()
        vc.title = "Create Account"
        navigationController?.pushViewController(vc, animated: true)
    }
    
    @objc private func didTapLogin() {
        
        emailTF.resignFirstResponder()
        passwordTF.resignFirstResponder()
        
        guard let email = emailTF.text, let password = passwordTF.text,
              !email.isEmpty, !password.isEmpty, password.count >= 6 else {
            alertUserLoginError()
            return
        }
        
        spinner.show(in: view)
        
        // Firebase login
        
        Auth.auth().signIn(withEmail: email, password: password) { [weak self] (authResult, error) in
            
            guard let strongSelf = self else {
                return
            }
            
            DispatchQueue.main.async {
                strongSelf.spinner.dismiss()
            }
            
            guard let result = authResult, error == nil else {
                print("\(email) Login error!")
                return
            }
            
            
            // success
            let user = result.user
            let safeEmail = DatabaseManager.safeEmail(emailAddress: email)
            
            DatabaseManager.shared.getDataFor(path: safeEmail, completion: { result in
                switch result {
                case .success(let data):
                    guard let userData = data as? [String: Any],
                          let firstName = userData["first_name"] as? String,
                          let lastName = userData["last_name"] as? String else {
                        return
                    }
                    
                    UserDefaults.standard.set("\(firstName) \(lastName)", forKey: "name")
                    
                case .failure(let error):
                    print("Failed to get data: - \(error.localizedDescription)")
                }
            })
            
            // save email, profile picture to device
            UserDefaults.standard.set(email, forKey: "email")
            
            
//            let formattedEmail = DatabaseManager.safeEmail(emailAddress: email)
//            UserDefaults.standard.set(formattedEmail+"_profile_picture.png", forKey: "profile_picture_url")
//            UserDefaults.standard.set(name, forKey: "current_username")
            
            print("\(user) Login Successful!")
            strongSelf.navigationController?.dismiss(animated: true, completion: nil)
        }
        
    }
    
    func alertUserLoginError() {
        let alert = UIAlertController(title: "Invalid log in", message: "Please enter all information to log in.", preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: "Dismiss", style: .cancel, handler: nil))
        
        present(alert, animated: true, completion: nil)
    }
    
    @objc private func didTapForgot() {
        print("Forgotten tapped")
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        scrollView.frame = view.bounds
//        scrollView.backgroundColor = .systemOrange
        
        let containerHeight = view.height*0.66
        container.frame = CGRect(
            x: 20,
            y: scrollView.height*0.20,
            width: scrollView.width-40,
            height: containerHeight)
//        container.backgroundColor = .systemPink
        
        let imageSize = container.width/4
        imageView.frame = CGRect(
            x: (container.width-imageSize)/2,
            y: container.height*0.1,
            width: imageSize,
            height: imageSize)
//        imageView.backgroundColor = .systemYellow
        
        emailTF.frame = CGRect(
            x: 0,
            y: imageView.bottom+(container.height*0.1),
            width: container.width,
            height: 40)
//        emailTF.backgroundColor = .systemGreen
        
        dividerView.frame = CGRect(
            x: -2,
            y: emailTF.bottom,
            width: view.width-36,
            height: 1)
//        dividerView.backgroundColor = .black
        
        passwordTF.frame = CGRect(
            x: 0,
            y: dividerView.bottom,
            width: container.width,
            height: 40)
//        passwordTF.backgroundColor = .systemTeal
        
        loginButton.frame = CGRect(
            x: 0,
            y: passwordTF.bottom+5,
            width: container.width,
            height: 40)
//        loginButton.backgroundColor = .systemBlue
        
        createAccountButton.frame = CGRect(
            x: 0,
            y: loginButton.bottom+10,
            width: container.width,
            height: 40)
//        createAccountButton.backgroundColor = .systemGreen
        
        forgotPasswordButton.frame = CGRect(
            x: 0,
            y: createAccountButton.bottom+10,
            width: container.width,
            height: 40)
//        forgotPasswordButton.backgroundColor = .systemGray
        
        let loginWithBtnSize = container.width/2.5
        
        fbLoginButton.frame = CGRect(
            x: (container.width-loginWithBtnSize)/2,
            y: forgotPasswordButton.bottom+10,
            width: loginWithBtnSize,
            height: 30)
        
        googleSignInButton.frame = CGRect(
            x: (container.width-loginWithBtnSize)/2,
            y: fbLoginButton.bottom+10,
            width: loginWithBtnSize,
            height: 30)
        
    }
    
    
    
}

extension LoginViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        
        if textField == emailTF {
            passwordTF.becomeFirstResponder()
        } else if textField == passwordTF {
            didTapLogin()
        }
        
        return true
    }
}

extension LoginViewController: LoginButtonDelegate {
    func loginButtonDidLogOut(_ loginButton: FBLoginButton) {
        // no operation
    }
    
    func loginButton(_ loginButton: FBLoginButton, didCompleteWith result: LoginManagerLoginResult?, error: Error?) {
        guard let token = result?.token?.tokenString else {
            print("Error logging in with facebook.")
            return
        }
        
        let facebookRequest = FBSDKLoginKit.GraphRequest(
            graphPath: "me",
            parameters: ["fields": "email, first_name, last_name, picture.type(large)"], // "fields": "email, name"
            tokenString: token,
            version: nil,
            httpMethod: .get)
        
        facebookRequest.start { (graphRequestConnection, result, error) in
            guard let result = result as? [String: Any],
                  error == nil else {
                print("Failed to make facebook graph request.")
                return
            }
            
            print("Facebook result - \(result)")
            
//            return
            
            guard let firstName = result["first_name"] as? String,
                  let lastName = result["last_name"] as? String,
                  let email = result["email"] as? String,
                  let picture = result["picture"] as? [String: Any],
                  let data = picture["data"] as? [String: Any],
                  let pictureUrl = data["url"] as? String
            else {
                print("failed to get email and name from facebook result.")
                return
            }
            
            // save email, name to device
            UserDefaults.standard.set(email, forKey: "email")
            UserDefaults.standard.set("\(firstName) \(lastName)", forKey: "name")
            
            DatabaseManager.shared.userExists(withEmail: email) { (exists) in
                if !exists {
                    let messengerUser = MessengerUser(firstName: firstName, lastName: lastName, emailAddress: email)
                    DatabaseManager.shared.insertUser(
                        withUser: messengerUser) { (success) in
                        if success {
                            
                            guard let url = URL(string: pictureUrl) else { return }
                            
                            print("Downloading data from facebook image.")
                            
                            URLSession.shared.dataTask(with: url) { (data, _, _) in
                                guard let data = data else {
                                    print("Failed to get data from facebook.")
                                    return
                                }
                                
                                print("Got data from facebook. Uploading...")
                                
                                // upload image
                                let fileName = messengerUser.profilePictureFileName
                                StorageManager.shared.uploadProfilePicture(
                                    withData: data,
                                    withfileName: fileName) { (result) in
                                    
                                    switch result {
                                    case .success(let downloadUrl):
                                        UserDefaults.standard.set(downloadUrl, forKey: "profile_picture_url")
                                        print(downloadUrl)
                                    case .failure(let error):
                                        print("Storage manager error: - \(error.localizedDescription)")
                                    }
                                }
                            }.resume()
                        }
                    }
                }
            }
            
            let credential = FacebookAuthProvider.credential(withAccessToken: token)
            
            Auth.auth().signIn(with: credential) { [weak self] (authResult, error) in
                guard let strongSelf = self else { return }
                
                guard authResult != nil, error == nil else {
                    if let error = error {
                        print("Facebook credential login failed, MFA may be needed. \(error)")
                    }
                    return
                }
                
                print("Login successfully with facebook.")
                strongSelf.navigationController?.dismiss(animated: true, completion: nil)
            }
        }
    }
    
    
}



//        /Users/mac/Library/Developer/Xcode/DerivedData/Messenger-ffcquztkrjieargpkkqzeabqiivj/Build/Products/Debug-iphonesimulator/Messenger.app.dSYM/Contents/Resources/DWARF/Messenger
