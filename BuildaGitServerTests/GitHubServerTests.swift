//  GitHubServerTests.swift
//  Buildasaur
//
//  Created by Honza Dvorsky on 12/12/2014.
//  Copyright (c) 2014 Honza Dvorsky. All rights reserved.
//

import Cocoa
import XCTest
@testable import BuildaGitServer
import BuildaUtils

class GitHubSourceTests: XCTestCase {

    var github: GitHubServer!

    override func setUp() {
        super.setUp()

        self.github = GitServerFactory.server(service: .GitHub, auth: nil) as! GitHubServer
    }

    override func tearDown() {

        self.github = nil

        super.tearDown()
    }

    func tryEndpoint(method: HTTP.Method, endpoint: GitHubEndpoints.Endpoint, params: [String: String]?, completion: @escaping (_ body: AnyObject?, _ error: Error?) -> Void) {

        let expect = expectation(description: "Waiting for url request")

        let request = try! self.github.endpoints.createRequest(method: method, endpoint: endpoint, params: params)

        _ = self.github.http.sendRequest(request as URLRequest, completion: { (_, body, error) -> Void in

            completion(body as AnyObject, error)
            expect.fulfill()
        })

        waitForExpectations(timeout: 10, handler: nil)
    }

    func testGetPullRequests() {

        let params = [
            "repo": "czechboy0/Buildasaur-Tester"
        ]

        self.tryEndpoint(method: .get, endpoint: .pullRequests, params: params) { (body, _) -> Void in

            XCTAssertNotNil(body, "Body must be non-nil")
            if let body = body as? NSArray {
                let prs: [GitHubPullRequest]? = try? GitHubArray(jsonArray: body)
                XCTAssertGreaterThan(prs?.count ?? -1, 0, "We need > 0 items to test parsing")
                Log.verbose("Parsed PRs: \(String(describing: prs))")
            } else {
                XCTFail("Body nil")
            }
        }
    }

    func testGetBranches() {

        let params = [
            "repo": "czechboy0/Buildasaur-Tester"
        ]

        self.tryEndpoint(method: .get, endpoint: .branches, params: params) { (body, _) -> Void in

            XCTAssertNotNil(body, "Body must be non-nil")
            if let body = body as? NSArray {
                let branches: [GitHubBranch]? = try? GitHubArray(jsonArray: body)
                XCTAssertGreaterThan(branches?.count ?? -1, 0, "We need > 0 items to test parsing")
                Log.verbose("Parsed branches: \(String(describing: branches))")
            } else {
                XCTFail("Body nil")
            }
        }
    }

    //manual parsing tested here, sort of a documentation as well

    func testUserParsing() {

        let dictionary = [
            "login": "czechboy0",
            "name": "Honza Dvorsky",
            "avatar_url": "https://avatars.githubusercontent.com/u/2182121?v=3",
            "html_url": "https://github.com/czechboy0"
        ]

        let user = try! GitHubUser(json: dictionary as NSDictionary)
        XCTAssertEqual(user.userName, "czechboy0")
        XCTAssertEqual(user.realName!, "Honza Dvorsky")
        XCTAssertEqual(user.avatarUrl!, "https://avatars.githubusercontent.com/u/2182121?v=3")
        XCTAssertEqual(user.htmlUrl!, "https://github.com/czechboy0")
    }

    func testRepoParsing() {

        let dictionary: NSDictionary = [
            "name": "Buildasaur",
            "full_name": "czechboy0/Buildasaur",
            "clone_url": "https://github.com/czechboy0/Buildasaur.git",
            "ssh_url": "git@github.com:czechboy0/Buildasaur.git",
            "html_url": "https://github.com/czechboy0/Buildasaur"
        ]

        let repo = try! GitHubRepo(json: dictionary)
        XCTAssertEqual(repo.name, "Buildasaur")
        XCTAssertEqual(repo.fullName, "czechboy0/Buildasaur")
        XCTAssertEqual(repo.repoUrlHTTPS, "https://github.com/czechboy0/Buildasaur.git")
        XCTAssertEqual(repo.repoUrlSSH, "git@github.com:czechboy0/Buildasaur.git")
        XCTAssertEqual(repo.htmlUrl!, "https://github.com/czechboy0/Buildasaur")
    }

    func testCommitParsing() {

        let dictionary: NSDictionary = [
            "sha": "08182438ed2ef3b34bd97db85f39deb60e2dcd7d",
            "url": "https://api.github.com/repos/czechboy0/Buildasaur/commits/08182438ed2ef3b34bd97db85f39deb60e2dcd7d"
        ]

        let commit = try! GitHubCommit(json: dictionary)
        XCTAssertEqual(commit.sha, "08182438ed2ef3b34bd97db85f39deb60e2dcd7d")
        XCTAssertEqual(commit.url!, "https://api.github.com/repos/czechboy0/Buildasaur/commits/08182438ed2ef3b34bd97db85f39deb60e2dcd7d")
    }

    func testBranchParsing() {

        let commitDictionary = [
            "sha": "08182438ed2ef3b34bd97db85f39deb60e2dcd7d",
            "url": "https://api.github.com/repos/czechboy0/Buildasaur/commits/08182438ed2ef3b34bd97db85f39deb60e2dcd7d"
        ]
        let dictionary: NSDictionary = [
            "name": "master",
            "commit": commitDictionary
        ]

        let branch = try! GitHubBranch(json: dictionary)
        XCTAssertEqual(branch.name, "master")
        XCTAssertEqual(branch.commit.sha, "08182438ed2ef3b34bd97db85f39deb60e2dcd7d")
        XCTAssertEqual(branch.commit.url!, "https://api.github.com/repos/czechboy0/Buildasaur/commits/08182438ed2ef3b34bd97db85f39deb60e2dcd7d")
    }

    func testPullRequestBranchParsing() {

        let dictionary: NSDictionary = [
            "ref": "fb-loadNode",
            "sha": "7e45fa772565969ee801b0bdce0f560122e34610",
            "user": [
                "login": "aleclarson",
                "avatar_url": "https://avatars.githubusercontent.com/u/1925840?v=3",
                "url": "https://api.github.com/users/aleclarson",
                "html_url": "https://github.com/aleclarson"
            ],
            "repo": [
                "name": "AsyncDisplayKit",
                "full_name": "aleclarson/AsyncDisplayKit",
                "owner": [
                    "login": "aleclarson",
                    "avatar_url": "https://avatars.githubusercontent.com/u/1925840?v=3",
                    "url": "https://api.github.com/users/aleclarson",
                    "html_url": "https://github.com/aleclarson"
                ],
                "html_url": "https://github.com/aleclarson/AsyncDisplayKit",
                "description": "Smooth asynchronous user interfaces for iOS apps.",
                "url": "https://api.github.com/repos/aleclarson/AsyncDisplayKit",
                "ssh_url": "git@github.com:aleclarson/AsyncDisplayKit.git",
                "clone_url": "https://github.com/aleclarson/AsyncDisplayKit.git"
            ]
        ]

        let prbranch = try! GitHubPullRequestBranch(json: dictionary)
        XCTAssertEqual(prbranch.ref, "fb-loadNode")
        XCTAssertEqual(prbranch.sha, "7e45fa772565969ee801b0bdce0f560122e34610")
        XCTAssertEqual(prbranch.repo.name, "AsyncDisplayKit")
    }

    func testResponseCaching() {
        //TODO
    }

}
