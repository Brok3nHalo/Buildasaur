//
//  BitBucketEnterprisePullRequestBranch.swift
//  Buildasaur
//
//  Created by Honza Dvorsky on 1/27/16.
//  Copyright © 2016 Honza Dvorsky. All rights reserved.
//
import Foundation
class BitBucketEnterprisePullRequestBranch: BitBucketEnterpriseEntity {

    let branch: String
    let commit: String
    let repo: BitBucketEnterpriseRepo

    required init(json: NSDictionary) throws {
        let name = try json.stringForKey("id").replacingOccurrences(of: "refs/heads/", with: "")
        self.branch = name
        self.commit = try json.stringForKey("latestCommit")
        self.repo = try BitBucketEnterpriseRepo(json: try json.dictionaryForKey("repository"))

        try super.init(json: json)
    }
}
