//
//  ViewController.swift
//  ChatApp
//
//  Created by Sphelele Zondo on 2018/08/07.
//  Copyright © 2018 SpheleleZondo. All rights reserved.
//

import UIKit
import JSQMessagesViewController

class ChatViewController: JSQMessagesViewController {
    
    var messages = [JSQMessage]()
    
    lazy var outgoingBubble:JSQMessagesBubbleImage = {
        return JSQMessagesBubbleImageFactory()!.incomingMessagesBubbleImage(with: .jsq_messageBubbleBlue())
    }()
    
    lazy var incomingBubble:JSQMessagesBubbleImage = {
        return JSQMessagesBubbleImageFactory()!.outgoingMessagesBubbleImage(with: .jsq_messageBubbleLightGray())
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let defaults = UserDefaults.standard
        
        if let id = defaults.string(forKey: "jsq_id"),
           let name = defaults.string(forKey: "jsq_name"){
           senderId = id
           senderDisplayName = name
        }else{
            senderId = String(arc4random_uniform(999999))
            senderDisplayName = ""
            defaults.set(senderId, forKey: "jsq_id")
            defaults.synchronize()
            showDisplayNameDialog()
        }
        title = "Chat: \(senderDisplayName!)"
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(showDisplayNameDialog))
        tapGesture.numberOfTapsRequired = 1
        navigationController?.navigationBar.addGestureRecognizer(tapGesture)
        inputToolbar.contentView.leftBarButtonItem = nil
        collectionView.collectionViewLayout.incomingAvatarViewSize = CGSize.zero
        collectionView.collectionViewLayout.outgoingAvatarViewSize = CGSize.zero
        let query = Constants.refs.databaseChats.queryLimited(toLast: 10)
        _ = query.observe(.childAdded, with: {[weak self] snapshot in
            if let data = snapshot.value as? [String:String],
               let id = data["sender_id"],
               let name = data["name"],
               let text = data["text"],
                !text.isEmpty{
                if let messge = JSQMessage(senderId: id, displayName: name, text: text){
                    self?.messages.append(messge)
                    self?.finishReceivingMessage()
                }
            }
        })
    }
    
    @objc func showDisplayNameDialog(){
        let defaults = UserDefaults.standard
        let alert = UIAlertController(title: "Your Display Name", message: "Before you can chat, please choose  a display name. Others will see this name you send chat messages. You can change your display name again by tapping the navigation bar.", preferredStyle: .alert)
        alert.addTextField{ textfield in
            if let name = defaults.string(forKey: "jsq_name"){
                textfield.text = name
            }else{
                let names = ["Ford", "Arthur", "Zaphod", "Trillian", "Slartibartfast", "Humma Kavula", "Deep Thought"]
                textfield.text = names[Int(arc4random_uniform(UInt32(names.count)))]
            }
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: {[weak self, weak alert] _ in
                if let textfield = alert?.textFields?[0], !textfield.text!.isEmpty{
                    self?.senderDisplayName = textfield.text
                    self?.title = "Chat: \(self!.senderDisplayName)"
                    defaults.set(textfield.text, forKey: "jsq_name")
                    defaults.synchronize()
                }
            }))
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    override func collectionView(_ collectionView:JSQMessagesCollectionView!, messageDataForItemAt indexPath:IndexPath!)->JSQMessageData!{
        return messages[indexPath.item]
    }
    
    override func collectionView(_ collectionView:UICollectionView, numberOfItemsInSection section:Int)->Int{
        return messages.count
    }
    
    override func collectionView(_ collectionView:JSQMessagesCollectionView!, messageBubbleImageDataForItemAt indexPath:IndexPath!)->JSQMessageBubbleImageDataSource!{
        return messages[indexPath.item].senderId == senderId ? outgoingBubble : incomingBubble
    }
    
    override func collectionView(_ collectionView:JSQMessagesCollectionView!, avatarImageDataForItemAt indexPath:IndexPath!)->JSQMessageAvatarImageDataSource!{
        return nil
    }
    
    override func collectionView(_ collectionView:JSQMessagesCollectionView!, attributedTextForMessageBubbleTopLabelAt indexPath:IndexPath!)->NSAttributedString!{
        return messages[indexPath.item].senderId == senderId ? nil : NSAttributedString(string:messages[indexPath.item].senderDisplayName)
    }
    
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, layout collectionViewLayout: JSQMessagesCollectionViewFlowLayout!, heightForMessageBubbleTopLabelAt indexPath: IndexPath!) -> CGFloat {
        return messages[indexPath.item].senderId == senderId ? 0 : 15
    }
    
    override func didPressSend(_ button: UIButton!, withMessageText text: String!, senderId: String!, senderDisplayName: String!, date: Date!) {
        let ref = Constants.refs.databaseChats.childByAutoId()
        let message = ["sender_id":senderId, "name":senderDisplayName, "text":text]
        ref.setValue(message)
        finishSendingMessage()
    }
}

