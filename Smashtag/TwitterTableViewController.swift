//
//  TwitterTableViewController.swift
//  Smashtag
//
//  Created by Wismin Effendi on 6/24/17.
//  Copyright © 2017 iShinobi. All rights reserved.
//

import UIKit
import Twitter 

class TwitterTableViewController: UITableViewController, UITextFieldDelegate {
    
    @IBOutlet weak var searchTextField: UITextField! {
        didSet {
            searchTextField.delegate = self
        }
    }
    
    private var tweets = [Array<Twitter.Tweet>]() {
        didSet {
            print(tweets)
        }
    }
    
    var searchText: String? {
        didSet {
            searchTextField?.text = searchText
            searchTextField?.resignFirstResponder()
            lastTwitterRequest = nil                    // REFRESHING
            tweets.removeAll()
            tableView.reloadData()
            searchForTweets()
            title = searchText
        }
    }
    
    private func twitterRequest() -> Twitter.Request? {
        if let query = searchText, !query.isEmpty {
            return Twitter.Request(search: "\(query) -filter:safe -filter:retweets", count: 100)
        }
        return nil
    }
    
    private var lastTwitterRequest: Twitter.Request?
  
    // takes the searchText part of our Model 
    // and fires off a fetch for matching Tweets 
    // when they come back (if they're still relevant)
    // we update our tweets array
    // and then let the table view know that we added a section 
    // (it will then call our UITableViewDataSource to get what it needs)
    
    private func searchForTweets() {
        // "lastTwitterRequest?.newer ?? " as added after lecture #9 for REFRESHING
        if let request = lastTwitterRequest?.newer ??  twitterRequest() {
            lastTwitterRequest = request
            request.fetchTweets { [weak self] newTweets in    // this is off the mai queue
                DispatchQueue.main.async {                    // so we must dispatch back to main queue
                    if request == self?.lastTwitterRequest {
                        self?.tweets.insert(newTweets, at: 0)  // put on the top
                        self?.tableView.insertSections([0], with: .fade)
                    }
                    self?.refreshControl?.endRefreshing()    // REFRESHING
                }
            }
        } else {
            self.refreshControl?.endRefreshing()             // REFRESHING
        }
    }
    

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.estimatedRowHeight = tableView.rowHeight
        tableView.rowHeight = UITableViewAutomaticDimension
    }
    
    // Added after lecture #9
    @IBAction func refresh(_ sender: UIRefreshControl) {
        searchForTweets()
    }

    // MARK: - Delegate for UITextField
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == searchTextField {
            searchText = searchTextField.text
        }
        return true
    }
    
    

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return tweets.count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tweets[section].count
    }

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Tweet", for: indexPath)

        let tweet: Tweet = tweets[indexPath.section][indexPath.row]

        if let tweetCell = cell as? TweetTableViewCell {
            tweetCell.tweet = tweet
        }

        return cell
    }
    
    // Added after lecture #9 for REFRESHING 
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        // make it a little clerer when each pull from Twitter 
        // occurs in the table by setting section header titles 
        return "\(tweets.count - section)"
    }

  
}
