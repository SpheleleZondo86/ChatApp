//
//  Constants.swift
//  ChatApp
//
//  Created by Sphelele Zondo on 2018/08/07.
//  Copyright © 2018 SpheleleZondo. All rights reserved.
//

import Foundation
import Firebase

struct Constants {
    struct refs {
        static let databaseRoot = Database.database().reference()
        static let databaseChats = databaseRoot.child("chats")
    }
}
