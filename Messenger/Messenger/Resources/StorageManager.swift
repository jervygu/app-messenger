//
//  StorageManager.swift
//  Messenger
//
//  Created by Jervy Umandap on 6/5/21.
//

import Foundation
import FirebaseStorage


/// Allows you to get, fetch, upload files to Firebase Storage
final class StorageManager {
    
    static let shared = StorageManager()
    
    private init() {}
    
    private let storage = Storage.storage().reference()
    
    /*
     /images/jervygu-gmail-com_profile_picture.png
     */
    
    public typealias UploadPictureCompletion = (Result<String, Error>) -> Void
    
    /// Upload picture to firebase storage and returns completion with URL string to download
    public func uploadProfilePicture(withData data: Data, withfileName fileName: String, completion: @escaping UploadPictureCompletion) {
        storage.child("images/\(fileName)").putData(data, metadata: nil) { [weak self] (storageMetadata, error) in
            
            guard let strongSelf = self else {
                return
            }
            
            guard error == nil else {
                // failed
                print("Failed to upload data to Firebase for picture.")
                completion(.failure(StorageErrors.failedToUpload))
                return
            }
            
            strongSelf.storage.child("images/\(fileName)").downloadURL { (url, error) in
                guard let url = url else {
                    print("Failed to get download Url.")
                    completion(.failure(StorageErrors.failedToGetDownloadUrl))
                    return
                }
                
                let urlString = url.absoluteString
                print("Download URL: - \(urlString)")
                
                completion(.success(urlString))
            }
        }
    }
    
    /// Upload image that will be sent in a conversation message
    public func uploadMessagePhoto(withData data: Data, withfileName fileName: String, completion: @escaping UploadPictureCompletion) {
        storage.child("message_images/\(fileName)").putData(data, metadata: nil) { [weak self] (storageMetadata, error) in
            guard error == nil else {
                // failed
                print("Failed to upload data to Firebase for picture.")
                completion(.failure(StorageErrors.failedToUpload))
                return
            }
            
            self?.storage.child("message_images/\(fileName)").downloadURL { (url, error) in
                guard let url = url else {
                    print("Failed to get download Url.")
                    completion(.failure(StorageErrors.failedToGetDownloadUrl))
                    return
                }
                
                let urlString = url.absoluteString
                print("Download URL: - \(urlString)")
                
                completion(.success(urlString))
            }
        }
    }
    
    /// Upload Video that will be sent in a conversation message
    public func uploadMessageVideo(withFileUrl fileUrl: URL, withfileName fileName: String, completion: @escaping UploadPictureCompletion) {
        storage.child("message_videos/\(fileName)").putFile(from: fileUrl, metadata: nil) { [weak self] (storageMetadata, error) in
            guard error == nil else {
                // failed
                print("Failed to upload video file to Firebase.")
                completion(.failure(StorageErrors.failedToUpload))
                return
            }
            
            self?.storage.child("message_videos/\(fileName)").downloadURL { (url, error) in
                guard let url = url else {
                    print("Failed to get download video Url.")
                    completion(.failure(StorageErrors.failedToGetDownloadUrl))
                    return
                }
                
                let urlString = url.absoluteString
                print("Download URL: - \(urlString)")
                
                completion(.success(urlString))
            }
        }
    }
    
    func getDownloadURL(forPath path: String, completion: @escaping (Result<URL, Error>) -> Void) {
        let reference = storage.child(path)
        
        reference.downloadURL(completion: { url, error in
            guard let url = url, error == nil else {
                completion(.failure(StorageErrors.failedToGetDownloadUrl))
                return
            }
            completion(.success(url))
            
        })
    }
    
    public enum StorageErrors: Error {
        case failedToUpload
        case failedToGetDownloadUrl
    }
}
