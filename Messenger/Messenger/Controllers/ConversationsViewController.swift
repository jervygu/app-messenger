//
//  ConversationsViewController.swift
//  Messenger
//
//  Created by Jervy Umandap on 6/1/21.
//

import UIKit
import Firebase
import JGProgressHUD

class ConversationsViewController: UIViewController {
    
    private let spinner = JGProgressHUD(style: .dark)
    
    private var conversations = [Conversation]()
    
    private let tableView: UITableView = {
        let table = UITableView()
        table.isHidden = true
        table.register(ConversationTableViewCell.self, forCellReuseIdentifier: ConversationTableViewCell.identifier)
        return table
    }()
    
    private let noConversationsLabel: UILabel = {
        let label = UILabel()
        label.text = "No Conversations yet."
        label.textAlignment = .left
        label.textColor = .label
        label.font = .systemFont(ofSize: 18, weight: .light)
        label.isHidden = true
        return label
    }()
    
    private var loginObserver: NSObjectProtocol?

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        title = "Chats"
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .compose,
            target: self,
            action: #selector(didTapComposeButton))
        
        view.addSubview(tableView)
        view.addSubview(noConversationsLabel)
        tableView.isHidden = false
        
        setupTableView()
//        fetchConversations()
        startListeningForConversations()
        
        
        // Observer
        loginObserver = NotificationCenter.default.addObserver(
            forName: .didLoginNotification,
            object: nil,
            queue: .main) { [weak self] (notification) in
            guard let strongSelf = self else {
                return
            }
            
            strongSelf.startListeningForConversations()
        }
        
        
        // userDefaults path
        let path: [AnyObject] = NSSearchPathForDirectoriesInDomains(.libraryDirectory, .userDomainMask, true) as [AnyObject]
        let folder: String = path[0] as! String
        print("Your NSUserDefaults are stored in this folder: %@/Preferences: \(folder)")
        
    }
    
    /// Fetch all conversations of the current user
    private func startListeningForConversations() {
        
        guard let email = UserDefaults.standard.value(forKey: "email") as? String else {
            return
        }
        
        if let observer = loginObserver {
            NotificationCenter.default.removeObserver(observer)
        }
        
        print("Start fetching conversation...")
        
        let safeEmail = DatabaseManager.safeEmail(emailAddress: email)
        
        DatabaseManager.shared.getAllConversations(for: safeEmail, completion: { [weak self] result in
            switch result {
            case .success(let conversations):
                
                print("Successfully got conversation models")
                guard !conversations.isEmpty else {
                    self?.tableView.isHidden = true
                    self?.noConversationsLabel.isHidden = false
                    return
                }
                
                self?.noConversationsLabel.isHidden = true
                self?.tableView.isHidden = false
                self?.conversations = conversations
                
                DispatchQueue.main.async {
                    self?.tableView.reloadData()
                }
                
            case .failure(let error):
                self?.tableView.isHidden = true
                self?.noConversationsLabel.isHidden = false
                print("Failed to get convos: \(error)")
            }
        })
    }
    
    
    @objc private func didTapComposeButton() {
        print("Compose tapped")
        
        let vc = NewConversationViewController()
        vc.completion = { [weak self] result in
            print(result)
            
            guard let strongSelf = self else {
                return
            }
            
            let currentConversations = strongSelf.conversations
            
            if let targetConversation = currentConversations.first(where: {
                // if true
                $0.otherUserEmail == DatabaseManager.safeEmail(emailAddress: result.email)
            }) {
                let vc = ChatViewController(with: targetConversation.otherUserEmail, id: targetConversation.id)
                vc.isNewConversation = false
                vc.title = targetConversation.name
                vc.navigationItem.largeTitleDisplayMode = .never
                strongSelf.navigationController?.pushViewController(vc, animated: true)
                
            } else {
                strongSelf.createNewConversation(result: result)
            }
            
        }
        
        let navVC = UINavigationController(rootViewController: vc)
        present(navVC, animated: true, completion: nil)
    }
    
    private func createNewConversation(result: SearchResult) {
        let name = result.name
        let email = DatabaseManager.safeEmail(emailAddress: result.email)
        
        // check if database has conversation with these two user exists
        
        DatabaseManager.shared.conversationExists(with: email, completion: { [weak self] result in
            guard let strongSelf = self else {
                return
            }
            
            switch result {
            case .success(let conversationID):
                let vc = ChatViewController(with: email, id: conversationID)
                vc.isNewConversation = false
                vc.title = name
                vc.navigationItem.largeTitleDisplayMode = .never
                strongSelf.navigationController?.pushViewController(vc, animated: true)
            
            case .failure(_):
                let vc = ChatViewController(with: email, id: nil)
                vc.isNewConversation = true
                vc.title = name
                vc.navigationItem.largeTitleDisplayMode = .never
                strongSelf.navigationController?.pushViewController(vc, animated: true)
            }
        })
        
        // if it does, reuse conversation ID
        // otherwise use existing code
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        validateAuth()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        tableView.frame = view.bounds
        
        noConversationsLabel.frame = CGRect(
            x: 16,
            y: view.safeAreaInsets.top+10,
            width: view.width-32,
            height: 44)
//        noConversationsLabel.backgroundColor = .systemRed

    }
    
    private func setupTableView() {
        tableView.delegate = self
        tableView.dataSource = self
    }
    
//    private func fetchConversations() {
//        // firebase
//        tableView.isHidden = false
//    }
    
    private func validateAuth() {
        if Auth.auth().currentUser == nil {
            let vc = LoginViewController()
            let nav = UINavigationController(rootViewController: vc)
            nav.modalPresentationStyle = .fullScreen
            
            present(nav, animated: false, completion: nil)
        }
    }
    


}

extension ConversationsViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return conversations.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let model = conversations[indexPath.row]
        
        let cell = tableView.dequeueReusableCell(withIdentifier: ConversationTableViewCell.identifier, for: indexPath) as! ConversationTableViewCell
        cell.configure(with: model)        
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let model = conversations[indexPath.row]
        openConversation(model)
    }
    
    func openConversation(_ model: Conversation) {
        let vc = ChatViewController(with: model.otherUserEmail, id: model.id)
        vc.title = model.name
        vc.navigationItem.largeTitleDisplayMode = .never
        navigationController?.pushViewController(vc, animated: true)
    }
    
    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        return .delete
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        
        if editingStyle == .delete {
            // begin delete
            
            let conversationID = conversations[indexPath.row].id
            
            tableView.beginUpdates()
            
            DatabaseManager.shared.deleteConversation(withConversationID: conversationID, completon: { [weak self] success in
                if success {
                    self?.conversations.remove(at: indexPath.row)
                    tableView.deleteRows(at: [indexPath], with: .left)
                }
            })
            tableView.endUpdates()
        }
    }
    
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60
    }
    
}

// part 16
// part 17 start
