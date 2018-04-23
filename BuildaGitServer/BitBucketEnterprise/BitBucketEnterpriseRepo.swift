//
//  BitBucketEnterpriseRepo.swift
//  Buildasaur
//
//  Created by Honza Dvorsky on 1/27/16.
//  Copyright © 2016 Honza Dvorsky. All rights reserved.
//
import Foundation
class BitBucketEnterpriseRepo: BitBucketEnterpriseEntity, RepoType {

    //kind of pointless here
    let permissions = RepoPermissions(read: true, write: true)
    let latestRateLimitInfo: RateLimitType? = BitBucketEnterpriseRateLimit()
    var originUrlSSH: String = ""

    required init(json: NSDictionary) throws {

        //split with forward slash, the last two comps are the repo
        //create a proper ssh url for bitbucket enterprise here
        let clones = try json
            .dictionaryForKey("links")
            .arrayForKey("clone")
        for case let clone as Dictionary<String, AnyObject> in clones {
            if let name = clone["name"] as? String, name == "ssh",
               let href = clone["href"] as? String {
                let url = NSURL(string: href)!
                self.originUrlSSH = url.absoluteString! //sshURL.host! + sshURL.path!
                break
            }
        }

        try super.init(json: json)
    }
}
