//
//  BitBucketEnterprisePullRequest.swift
//  Buildasaur
//
//  Created by Honza Dvorsky on 1/27/16.
//  Copyright © 2016 Honza Dvorsky. All rights reserved.
//
import Foundation
class BitBucketEnterprisePullRequest: BitBucketEnterpriseIssue, PullRequestType {

    let title: String
    let source: BitBucketEnterprisePullRequestBranch
    let destination: BitBucketEnterprisePullRequestBranch
    var repoName: String

    required init(json: NSDictionary) throws {

        self.title = try json.stringForKey("title")

        self.source = try BitBucketEnterprisePullRequestBranch(json: try json.dictionaryForKey("fromRef"))
        self.destination = try BitBucketEnterprisePullRequestBranch(json: try json.dictionaryForKey("toRef"))
        self.repoName = ""

        try super.init(json: json)
    }

    var headName: String {
        return self.source.branch
    }

    var headCommitSHA: String {
        return self.source.commit
    }

    var headRepo: RepoType {
        return self.source.repo
    }

    var baseName: String {
        return self.destination.branch
    }
}
