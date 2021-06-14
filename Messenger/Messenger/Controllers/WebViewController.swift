//
//  WebViewController.swift
//  Messenger
//
//  Created by Jervy Umandap on 6/14/21.
//

import UIKit
import WebKit

class WebViewController: UIViewController, WKUIDelegate {
    
    var webView: WKWebView!
    
    var webPageUrl: String?
     
    override func loadView() {
        let webConfiguration = WKWebViewConfiguration()
        webView = WKWebView(frame: .zero, configuration: webConfiguration)
        webView.uiDelegate = self
        view = webView
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        
        guard let urlString = webPageUrl,
              let myURL = URL(string: urlString) else {
            return
        }
        
        let myRequest = URLRequest(url: myURL)
        webView.load(myRequest)
    }

}
