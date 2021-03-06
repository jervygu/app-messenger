//
//  DatabaseManager.swift
//  Messenger
//
//  Created by Jervy Umandap on 6/2/21.
//

import Foundation
import FirebaseDatabase
import MessageKit
import CoreLocation


/// Manager object to read and write data to real time firebase database.
final class DatabaseManager {
    
    /// Shared instance of class
    public static let shared = DatabaseManager()
    private let database = Database.database().reference()
    
    static func safeEmail(emailAddress: String) -> String {
        var safeEmail = emailAddress.replacingOccurrences(of: ".", with: "-")
        safeEmail = safeEmail.replacingOccurrences(of: "@", with: "-")
        return safeEmail
    }
    
}

// MARK: - Account Management

extension DatabaseManager {
    
    /// Returns Dictionary node at child path
    public func getDataFor(path: String, completion: @escaping(Result<Any, Error>) -> Void) {
        database.child("\(path)").observeSingleEvent(of: .value, with: { snapshot in
            guard let value = snapshot.value else {
                completion(.failure(DatabaseError.failedToFetch))
                return
            }
            
            completion(.success(value))
        })
    }
    
}

extension DatabaseManager {
    
    /// Check if email does exist.
    /// Parameters:
    /// - `email`:                      Target email to be checked
    /// - `completion`:           Async closure to return with results
    public func userExists(withEmail email: String, completion: @escaping((Bool) -> Void)) {
        
//        var safeEmail = email.replacingOccurrences(of: ".", with: "-")
//        safeEmail = safeEmail.replacingOccurrences(of: "@", with: "-")
        
        let safeEmail = DatabaseManager.safeEmail(emailAddress: email)
        
        database.child(safeEmail).observeSingleEvent(of: .value) { (snapshot) in
            guard snapshot.value as? [String: Any] != nil else {
                completion(false)
                return
            }
            
            completion(true)
        }
    }
    
    /// Inserts new user to database.
    public func insertUser(withUser user: MessengerUser, completion: @escaping(Bool) -> Void) {
        database.child(user.safeEmail).setValue([
            "first_name": user.firstName,
            "last_name": user.lastName
        ], withCompletionBlock: { [weak self] (error, databaseReference) in
            
            guard let strongSelf = self else {
                return
            }
            
            guard error == nil else {
                print("failed to write to database")
                completion(false)
                return
            }
            
            // create new array or append to array of users
            strongSelf.database.child("users").observeSingleEvent(of: .value, with: { snapshot in
                if var usersCollection = snapshot.value as? [[String: String]] {
                    
                    // append to user dictionary
                    let newElement = [
                        "name": user.firstName + " " + user.lastName,
                        "email": user.safeEmail
                    ]
                    usersCollection.append(newElement)
                    
                    
                    strongSelf.database.child("users").setValue(usersCollection, withCompletionBlock: { error,_ in
                        guard error == nil else {
                            completion(false)
                            return
                        }
                        
                        completion(true)
                    })
                    
                } else {
                    
                    // create the array
                    let newCollection: [[String: String]] = [
                        [
                            "name": user.firstName + " " + user.lastName,
                            "email": user.safeEmail
                        ]
                    ]
                    strongSelf.database.child("users").setValue(newCollection, withCompletionBlock: { error,_ in
                        guard error == nil else {
                            completion(false)
                            return
                        }
                        
                        completion(true)
                    })
                }
            })
            // upload the photo to firebase
            completion(true)
        })
    }
    
    
    /// Fetch all users of Messenger app
    public func getAllUsers(completion: @escaping (Result<[[String: String]], Error>) -> Void) {
        database.child("users").observeSingleEvent(of: .value, with: { snapshot in
            guard let value = snapshot.value as? [[String: String]] else {
                completion(.failure(DatabaseError.failedToFetch))
                return
            }
            
            completion(.success(value))
        })
    }
    
    public enum DatabaseError: Error {
        case failedToFetch
        
        public var localizedDescription: String {
            switch self {
            case.failedToFetch:
                return "Error occured fetching data."
            }
        }
    }
    
    
    
}


// MARK: - SENDING MESSAGES / CONVERSATION


extension DatabaseManager {
    
    /// Create a new conversation with target user email and firstMessage sent
    public func createNewConversation(with otherUserEmail: String, name: String, firstMessage: Message, completion: @escaping(Bool) -> Void) {
        guard let currentUserEmail = UserDefaults.standard.value(forKey: "email") as? String,
              let currentUserName = UserDefaults.standard.value(forKey: "name") as? String else {
            return
        }
        
        let safeEmail = DatabaseManager.safeEmail(emailAddress: currentUserEmail)
        
        let reference = database.child("\(safeEmail)")
        
        reference.observeSingleEvent(of: .value, with: { [weak self] snapshot in
            guard var userNode = snapshot.value as? [String: Any] else {
                completion(false)
                print("User not found")
                return
            }
            
            let messageDate = firstMessage.sentDate
            let dateString = ChatViewController.dateFormatter.string(from: messageDate)
            
            var message = ""
            
            switch firstMessage.kind {
            case .text(let messageText):
                message = messageText
            case .attributedText(_):
                break
            case .photo(_):
                break
            case .video(_):
                break
            case .location(_):
                break
            case .emoji(_):
                break
            case .audio(_):
                break
            case .contact(_):
                break
            case .linkPreview(_):
                break
            case .custom(_):
                break
            }
            
            let conversationID = "conversation_\(firstMessage.messageId)"
            
            let newConversationData: [String: Any] = [
                "id": conversationID,
                "other_user_email": otherUserEmail,
                "name": name,
                "latest_message": [
                    "date": dateString,
                    "text": message,
                    "is_read": false
                ]
            ]
            
            // save to recipient database
            let recipient_newConversationData: [String: Any] = [
                "id": conversationID,
                "other_user_email": safeEmail,
                "name": currentUserName,
                "latest_message": [
                    "date": dateString,
                    "text": message,
                    "is_read": false
                ]
            ]
            
            // Update recipient user conversation entry
            self?.database.child("\(otherUserEmail)/conversations").observeSingleEvent(of: .value, with: { [weak self] snapshot in
                if var conversations = snapshot.value as? [[String: Any]] {
                    // append
                    conversations.append(recipient_newConversationData)
                    self?.database.child("\(otherUserEmail)/conversations").setValue([conversations])
                    
                } else {
                    // create
                    self?.database.child("\(otherUserEmail)/conversations").setValue([recipient_newConversationData])
                    
                }
                
            })
            
            // Update current user conversation entry
            if var conversations = userNode["conversations"] as? [[String: Any]] {
                // conversation array exists for current user
                // you should append
                
                conversations.append(newConversationData)
                
                userNode["conversations"] = conversations
                
                reference.setValue(userNode, withCompletionBlock: { [weak self] error,_ in
                    
                    guard error == nil else {
                        print(error?.localizedDescription as Any)
                        completion(false)
                        return
                    }
                    
                    self?.finishCreatingConversation(name: name,
                                                     conversationID: conversationID,
                                                     firstMessage: firstMessage,
                                                     completion: completion)
                })
                
            } else {
                // conversation array does not exist
                // create array
                
                userNode["conversations"] = [
                    newConversationData
                ]
                
                reference.setValue(userNode, withCompletionBlock: { [weak self] error,_ in
                    guard error == nil else {
                        print(error?.localizedDescription as Any)
                        completion(false)
                        return
                    }
                    
                    self?.finishCreatingConversation(name: name,
                                                     conversationID: conversationID,
                                                     firstMessage: firstMessage,
                                                     completion: completion)
                })
            }
        })
        
    }
    
    /// Finish creating conversations
    private func finishCreatingConversation(name: String, conversationID: String, firstMessage: Message, completion: @escaping(Bool) -> Void) {
        
        let messageDate = firstMessage.sentDate
        let dateString = ChatViewController.dateFormatter.string(from: messageDate)
        
        var message = ""
        
        switch firstMessage.kind {
        case .text(let messageText):
            message = messageText
        case .attributedText(_):
            break
        case .photo(_):
            break
        case .video(_):
            break
        case .location(_):
            break
        case .emoji(_):
            break
        case .audio(_):
            break
        case .contact(_):
            break
        case .linkPreview(_):
            break
        case .custom(_):
            break
        }
        
        guard let myEmail = UserDefaults.standard.value(forKey: "email") as? String else {
            completion(false)
            return
        }
        
        let currentUserEmail = DatabaseManager.safeEmail(emailAddress: myEmail)
        
        let collectionMessage: [String: Any] = [
            "id": firstMessage.messageId,
            "type": firstMessage.kind.messageKindString,
            "content": message,
            "date": dateString,
            "sender_email": currentUserEmail,
            "is_read": false,
            "recipient_name": name
        ]
        
        let value: [String: Any] = [
            "messages" : [
                collectionMessage
            ]
        ]
        
        print("Adding convo: - \(conversationID)")
        
        database.child("\(conversationID)").setValue(value, withCompletionBlock: { error,_ in
            guard error == nil else {
                completion(false)
                return
            }
            completion(true)
        })
    }
    
    /// Fetches and returns all conversations for the user with passed email
    public func getAllConversations(for email: String, completion: @escaping(Result<[Conversation], Error>) -> Void) {
        
        database.child("\(email)/conversations").observe(.value, with: { snapshot in
            
            guard let value = snapshot.value as? [[String: Any]] else {
                completion(.failure(DatabaseError.failedToFetch))
                return
            }
            
            print("Value in fetching conversations: - \(value)")
            
            let conversations: [Conversation] = value.compactMap({ dictionary in
                
                guard let conversationID = dictionary["id"] as? String,
                      let name = dictionary["name"] as? String,
                      let otherUserEmail = dictionary["other_user_email"] as? String,
                      let latestMessage = dictionary["latest_message"] as? [String: Any],
                      let dateSent = latestMessage["date"] as? String,
                      let isRead = latestMessage["is_read"] as? Bool,
                      let text = latestMessage["text"] as? String else {
                    return nil
                }
                
                
                
                let latestMessageObject = LatestMessage(date: dateSent, text: text, isRead: isRead)
                
                return Conversation(id: conversationID,
                                    name: name,
                                    otherUserEmail: otherUserEmail,
                                    latestMessage: latestMessageObject)
            })
            completion(.success(conversations))
        })
    }
    
    /// Get all messages for a given conversation
    public func getAllMessagesForConversation(withID id: String, completion: @escaping(Result<[Message], Error>) -> Void) {
        
        database.child("\(id)/messages").observe(.value, with: { snapshot in
            
            guard let value = snapshot.value as? [[String: Any]] else {
                completion(.failure(DatabaseError.failedToFetch))
                return
            }

            let messages: [Message] = value.compactMap({ dictionary in
                guard let messageID = dictionary["id"] as? String,
                      let type = dictionary["type"] as? String,
                      let content = dictionary["content"] as? String,
                      let dateString = dictionary["date"] as? String,
                      let formattedDate = ChatViewController.dateFormatter.date(from: dateString),
                      let senderEmail = dictionary["sender_email"] as? String,
                      let isRead = dictionary["is_read"] as? Bool,
                      let recipient_name = dictionary["recipient_name"] as? String else {
                    return nil
                }
                
                var kind: MessageKind?
                
                if type == "photo" {
                    // photo
                    guard let imageUrl = URL(string: content),
                          let placeholder = UIImage(systemName: "photo") else {
                        return nil
                    }
                    
                    let media = Media(url: imageUrl,
                                      image: nil,
                                      placeholderImage: placeholder,
                                      size: CGSize(width: 250, height: 200))
                    
                    kind = .photo(media)
                } else if type == "video" {
                    // video
                    guard let videoUrl = URL(string: content),
                          let placeholder = UIImage(named: "video_placeholder") else {
                        return nil
                    }
                    
                    let media = Media(url: videoUrl,
                                      image: nil,
                                      placeholderImage: placeholder,
                                      size: CGSize(width: 250, height: 200))
                    
                    kind = .video(media)
                } else if type == "location" {
                    // location
                    let locationComponents = content.components(separatedBy: ",")
                    guard let longitude = Double(locationComponents[0]),
                          let latitude = Double(locationComponents[1]) else {
                        return nil
                    }
                    
                    let location = Location(
                        location: CLLocation(
                            latitude: latitude,
                            longitude: longitude),
                        size: CGSize(width: 250, height: 200))
                    
                    kind = .location(location)
                } else {
                    kind = .text(content)
                    
                }
                
                guard let finalKind = kind else {
                    return nil
                }
                
                let senderType = Sender(photoDataString: "", senderId: senderEmail, displayName: recipient_name)
                
                let messagesObject = Message(sender: senderType,
                                             messageId: messageID,
                                             sentDate: formattedDate,
                                             kind: finalKind)
                return messagesObject
            })
            completion(.success(messages))
        })
    }
    
    /// Sends message with target conversation and message
    public func sendMessage(toConversation conversation: String, otherUserEmail: String, name: String, newMessage: Message, completion: @escaping(Bool) -> Void) {
        // add new message to messages
        // update sender latst message
        // update recipient later message
        
        guard let myEmail = UserDefaults.standard.value(forKey: "email") as? String else {
            return
        }
        
        let currentUserEmail = DatabaseManager.safeEmail(emailAddress: myEmail)
        
        database.child("\(conversation)/messages").observeSingleEvent(of:. value, with: { [weak self] snapshot in
            guard let strongSelf = self else {
                completion(false )
                return
            }
            
            guard var currentMessages = snapshot.value as? [[String: Any]] else {
                completion(false)
                return
            }
            
            
            let messageDate = newMessage.sentDate
            let dateString = ChatViewController.dateFormatter.string(from: messageDate)
            
            var message = ""
            
            switch newMessage.kind {
            case .text(let messageText):
                message = messageText
            case .attributedText(_):
                break
            case .photo(let mediaItem):
                if let targetUrlString = mediaItem.url?.absoluteString {
                    message = targetUrlString
                }
                break
            case .video(let mediaItem):
                if let targetUrlString = mediaItem.url?.absoluteString {
                    message = targetUrlString
                }
                break
            case .location(let locationData):
                let location = locationData.location
                message = "\(location.coordinate.longitude),\(location.coordinate.latitude)"
                break
            case .emoji(_):
                break
            case .audio(_):
                break
            case .contact(_):
                break
            case .linkPreview(_):
                break
            case .custom(_):
                break
            }
            
            guard let myEmail = UserDefaults.standard.value(forKey: "email") as? String else {
                completion(false)
                return
            }
            
            let currentUserEmail = DatabaseManager.safeEmail(emailAddress: myEmail)
            
            let newMessageEntry: [String: Any] = [
                "id": newMessage.messageId,
                "type": newMessage.kind.messageKindString,
                "content": message,
                "date": dateString,
                "sender_email": currentUserEmail,
                "is_read": false,
                "recipient_name": name
            ]
            
            currentMessages.append(newMessageEntry)
            
            strongSelf.database.child("\(conversation)/messages").setValue(currentMessages, withCompletionBlock: { error,_ in
                guard error == nil else {
                    completion(false)
                    return
                }
                
                strongSelf.database.child("\(currentUserEmail)/conversations").observeSingleEvent(of: .value, with: { snapshot in
                    
                    var databaseEntryConversations = [[String: Any]]()
                    
                    let updatedValue: [String: Any] = [
                        "date": dateString,
                        "text": message,
                        "is_read": false
                    ]
                    
                    // if find the collection
                    if var currentUserConversation = snapshot.value as? [[String: Any]] {
                        var targetConversation: [String: Any]?
                        var position = 0
                        
                        for conversationDictionary in currentUserConversation {
                            if let currentConversationID = conversationDictionary["id"] as? String,
                               currentConversationID == conversation {
                                targetConversation = conversationDictionary
                                break
                            }
                            position += 1
                        }
                        
                        // before we assume we find it, if exist. do the update
                        if var targetConversation = targetConversation {
                            targetConversation["latest_message"] = updatedValue
                            currentUserConversation[position] = targetConversation
                            databaseEntryConversations = currentUserConversation
                            
                        } else {
                            // craete anew conversation data
                            let newConversationData: [String: Any] = [
                                "id": conversation,
                                "other_user_email": DatabaseManager.safeEmail(emailAddress: otherUserEmail),
                                "name": name,
                                "latest_message": updatedValue
                            ]
                            
                            // append as a new fresh entry
                            currentUserConversation.append(newConversationData)
                            databaseEntryConversations = currentUserConversation
                            
                        }
                        
                    } else {
                        
                        let newConversationData: [String: Any] = [
                            "id": conversation,
                            "other_user_email": DatabaseManager.safeEmail(emailAddress: otherUserEmail),
                            "name": name,
                            "latest_message": updatedValue
                        ]
                        
                        databaseEntryConversations = [newConversationData]
                    }
                    
                    
                    strongSelf.database.child("\(currentUserEmail)/conversations").setValue(databaseEntryConversations, withCompletionBlock: { error,_ in
                        guard error == nil else {
                            completion(false)
                            return
                        }
                        
                        // update latest message for recipient user
                        strongSelf.database.child("\(otherUserEmail)/conversations").observeSingleEvent(of: .value, with: { snapshot in
                            
                            let updatedValue: [String: Any] = [
                                "date": dateString,
                                "text": message,
                                "is_read": false
                            ]
                            
                            guard let currentUsername = UserDefaults.standard.value(forKey: "name") as? String else {
                                return
                            }
                            
                            var databaseEntryConversations = [[String: Any]]()
                            
                            if var otherUserConversation = snapshot.value as? [[String: Any]] {
                                var targetConversation: [String: Any]?
                                
                                var position = 0
                                
                                for conversationDictionary in otherUserConversation {
                                    if let currentConversationID = conversationDictionary["id"] as? String,
                                       currentConversationID == conversation {
                                        targetConversation = conversationDictionary
                                        break
                                    }
                                    position += 1
                                }
                                
                                if var targetConversation = targetConversation {
                                    targetConversation["latest_message"] = updatedValue
                                    
                                    otherUserConversation[position] = targetConversation
                                    databaseEntryConversations = otherUserConversation
                                    
                                } else {
                                    // failed to find in current collection
                                    
                                    let newConversationData: [String: Any] = [
                                        "id": conversation,
                                        "other_user_email": DatabaseManager.safeEmail(emailAddress: currentUserEmail),
                                        "name": currentUsername,
                                        "latest_message": updatedValue
                                    ]
                                    
                                    // append as a new fresh entry
                                    otherUserConversation.append(newConversationData)
                                    databaseEntryConversations = otherUserConversation
                                }
                                
                            } else {
                                // current collection does not exist
                                
                                let newConversationData: [String: Any] = [
                                    "id": conversation,
                                    "other_user_email": DatabaseManager.safeEmail(emailAddress: currentUserEmail),
                                    "name": currentUsername,
                                    "latest_message": updatedValue
                                ]
                                
                                databaseEntryConversations = [newConversationData]
                            }
                            
                            
                            strongSelf.database.child("\(otherUserEmail)/conversations").setValue(databaseEntryConversations, withCompletionBlock: { error,_ in
                                guard error == nil else {
                                    completion(false)
                                    return
                                }
                                
                                completion(true)
                            })
                        })
//                        completion(true)
                    })
                })
//                completion(true)
            })
        })
    }
    
    
    public func deleteConversation(withConversationID conversationID: String, completon: @escaping(Bool) -> Void) {
        guard let email = UserDefaults.standard.value(forKey: "email") as? String else {
            return
        }
        
        let safeEmail = DatabaseManager.safeEmail(emailAddress: email)
        
        print("Deleting conversation with ID: - \(conversationID)")
        
        // get all conversations for current user
        // delete conversations in collection with target ID
        
        
        // reset those conversations for the user in database
        let ref = database.child("\(safeEmail)/conversations")
        ref.observeSingleEvent(of: .value, with: { snapshot in
            if var conversations = snapshot.value as? [[String: Any]] {
                var positionToRemove = 0
                for item in conversations {
                    if let id = item["id"] as? String,
                       id == conversationID {
                        print("Found conversation to delete")
                        break
                    }
                    positionToRemove += 1
                }
                
                conversations.remove(at: positionToRemove)
                
                ref.setValue(conversations, withCompletionBlock: { error, _ in
                    guard error == nil else {
                        print("Failed to write new conversation Array")
                        completon(false)
                        return
                    }
                    print("Successfully deleted conversation.")
                    completon(true)
                })
            }
        })
    }
    
    
    public func conversationExists(with targetRecipientEmail: String, completion: @escaping(Result<String, Error>) -> Void) {
        let safeRecipientEmail = DatabaseManager.safeEmail(emailAddress: targetRecipientEmail)
        
        guard let senderEmail = UserDefaults.standard.value(forKey: "email") as? String else {
            return
        }
        
        let safeSenderEmail = DatabaseManager.safeEmail(emailAddress: senderEmail)
        
        database.child("\(safeRecipientEmail)/conversations").observeSingleEvent(of: .value, with: { snapshot in
            guard let collection = snapshot.value as? [[String: Any]] else {
                completion(.failure(DatabaseError.failedToFetch))
                return
            }
            
            // iterate and find conversation with target sender
            if let conversation = collection.first(where: {
                guard let targetSenderEmail = $0["other_user_email"] as? String else {
                    return false
                }
                return safeSenderEmail == targetSenderEmail
            }) {
                // get id
                guard let id = conversation["id"] as? String else {
                    completion(.failure(DatabaseError.failedToFetch))
                    return
                }
                
                completion(.success(id))
                return
                
            }
            completion(.failure(DatabaseError.failedToFetch))
            return
        })
    }
    
}


struct MessengerUser {
    let firstName: String
    let lastName: String
    let emailAddress: String
    
    var safeEmail: String {
        var safeEmail = emailAddress.replacingOccurrences(of: ".", with: "-")
        safeEmail = safeEmail.replacingOccurrences(of: "@", with: "-")
        return safeEmail
    }
    
    var profilePictureFileName: String {
        return "\(safeEmail)_profile_picture.png"
    }
}
 

// part 14
