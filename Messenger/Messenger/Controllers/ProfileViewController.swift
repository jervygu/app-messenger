//
//  ProfileViewController.swift
//  Messenger
//
//  Created by Jervy Umandap on 6/1/21.
//

import UIKit
import Firebase
import FBSDKLoginKit
import GoogleSignIn

enum ProfileViewModelType {
    case logout, legalPolicies, help
}

struct ProfileViewModel {
    let viewModelType: ProfileViewModelType
    let title: String
    let iconName: String
    let color: UIColor
//    let color: UIColor
    let handler: (() -> Void)?
}

class ProfileViewController: UIViewController {
    
    
    @IBOutlet weak var tableView: UITableView!
    
//    private var tableView: UITableView = {
//        let table = UITableView()
//        return table
//    }()
    
//    "Account settings", "Legal and policies"
    var profileOptions = [ProfileViewModel]()
    

    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .systemBackground
        title = "Profile"
        
        tableView.register(ProfileTableViewCell.self, forCellReuseIdentifier: ProfileTableViewCell.identifier)
        
        profileOptions.append(
            ProfileViewModel(viewModelType: .help,
                             title: "Help",
                             iconName: "questionmark.circle.fill",
                             color: UIColor.systemBlue,
                             handler: { [weak self] in
                                self?.goToWebPage(urlString: "https://www.facebook.com/terms.php",
                                            title: "Help Center")
                             }))
        
        profileOptions.append(
            ProfileViewModel(viewModelType: .legalPolicies,
                             title: "Legal & Policies",
                             iconName: "doc.text.fill",
                             color: UIColor.systemGray,
                             handler: { [weak self] in
                                self?.goToWebPage(urlString: "https://www.facebook.com/terms.php",
                                            title: "Legal & Policies")
                                
                             }))
        
        profileOptions.append(
            ProfileViewModel(viewModelType: .logout,
                             title: "Log Out",
                             iconName: "arrow.2.circlepath.circle.fill",
                             color: UIColor.systemRed,
                             handler: { [weak self] in
                                guard let strongSelf = self else {
                                    return
                                }
                                strongSelf.didTapLogout()
                             }))
        
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        tableView.delegate = self
        tableView.dataSource = self
        tableView.tableHeaderView = createTableHeader()
        
        
        
//        view.addSubview(tableView)
    }
    
    func goToWebPage(urlString: String, title: String) {
        let vc = WebViewController()
        vc.webPageUrl = urlString
        vc.title = title
        vc.navigationItem.largeTitleDisplayMode = .never
        navigationController?.pushViewController(vc, animated: true)
    }
    
    func createTableHeader() -> UIView? {
        guard let email = UserDefaults.standard.value(forKey: "email") as? String else {
            return nil
        }
        
        let safeEmail = DatabaseManager.safeEmail(emailAddress: email)
        let fileName = safeEmail + "_profile_picture.png"
        let path = "images/"+fileName
        
        let headerView = UIView(
            frame: CGRect(x: 0,
                          y: 0,
                          width: self.view.width,
                          height: 200))
        headerView.backgroundColor = .systemGray5
        
        let imageSize: CGFloat = headerView.height/2
        let imageView = UIImageView(
            frame: CGRect(x: (headerView.width-imageSize)/2,
                          y: 30,
                          width: imageSize,
                          height: imageSize))
        
        imageView.contentMode = .scaleAspectFill
        imageView.layer.cornerRadius = imageSize/2
//        imageView.layer.borderWidth = 1
//        imageView.layer.borderColor = UIColor.systemGray.cgColor
        imageView.layer.masksToBounds = true
        
        let labelWidth: CGFloat = headerView.width/2
        let label = UILabel(
            frame: CGRect(x: (headerView.width-labelWidth)/2,
                          y: imageView.bottom+15,
                          width: labelWidth,
                          height: 30))
        label.textAlignment = .center
        label.numberOfLines = 0
        label.font = .systemFont(ofSize: 22, weight: .medium)
//        label.text = Auth.auth().currentUser?.email
        let userName = UserDefaults.standard.value(forKey: "name") as? String
        label.text = userName?.capitalized
//        label.backgroundColor = .systemPink
        
        
        headerView.addSubview(imageView)
        headerView.addSubview(label)
        
        StorageManager.shared.getDownloadURL(forPath: path, completion: { result in
            // [weak self] - to avoid retain cycle to the memory
            
            switch result {
            case .success(let url):
                imageView.sd_setImage(with: url, completed: nil)
            case .failure(let error):
                print("Failed to get download url: \(error)")
            }
        })
        
        return headerView
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
//        tableView.frame = view.bounds
        
    }
    
    private func didTapLogout() {
        let actionSheet = UIAlertController(title: "Log Out", message: "Are you sure you want to log out?", preferredStyle: .actionSheet)
        
        actionSheet.addAction(UIAlertAction(
                                title: "Cancel",
                                style: .cancel,
                                handler: nil))
        
        actionSheet.addAction(UIAlertAction(
                                title: "Log out",
                                style: .destructive,
                                handler: { [weak self] (action) in
                                    guard let strongSelf = self else { return }
                                    
                                    // Facebook Logout
                                    FBSDKLoginKit.LoginManager().logOut()
                                    
                                    // Google signOut
                                    GIDSignIn.sharedInstance()?.signOut()
                                    
                                    // UserDefaults set to nil when logged out
                                    //                                    UserDefaults.standard.set(nil, forKey: "email")
                                    //                                    UserDefaults.standard.set(nil, forKey: "profile_picture_url")
                                    //
                                    //                                    print(UserDefaults.standard.value(forKey: "email") ?? "Email not set")
                                    //                                    print(UserDefaults.standard.value(forKey: "profile_picture_url")  ?? "Profile pic not set")
                                    
                                    //TODO: Log out the user and send them back to WelcomeViewController
                                    do {
                                        try Auth.auth().signOut()
                                        let vc = LoginViewController()
                                        let nav = UINavigationController(rootViewController: vc)
                                        nav.modalPresentationStyle = .fullScreen
                                        
                                        strongSelf.present(nav, animated: false, completion: nil)
                                    } catch {
                                        print("Error, there was a problem signing out.")
                                    }
                                }))
        
        present(actionSheet, animated: true, completion: nil)
    }

}

extension ProfileViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return profileOptions.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let viewModel = profileOptions[indexPath.row]
        
        let cell = tableView.dequeueReusableCell(withIdentifier: ProfileTableViewCell.identifier, for: indexPath) as! ProfileTableViewCell
        
//        cell.textLabel?.text = profileOptions[indexPath.row].title
        cell.setUp(withModel: viewModel)
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        profileOptions[indexPath.row].handler?()
        
        
    }
    
}
