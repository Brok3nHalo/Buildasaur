//
//  BitBucketEnterpriseServer.swift
//  Buildasaur
//
//  Created by Honza Dvorsky on 1/27/16.
//  Copyright © 2016 Honza Dvorsky. All rights reserved.
//
import Foundation
import BuildaUtils
class BitBucketEnterpriseServer: GitServer<BitBucketEnterpriseService> {

    let endpoints: BitBucketEnterpriseEndpoints
    let cache = InMemoryURLCache()

    init(endpoints: BitBucketEnterpriseEndpoints, service: BitBucketEnterpriseService, http: HTTP? = nil) {

        self.endpoints = endpoints
        super.init(service: service, http: http)
    }
}
extension BitBucketEnterpriseServer: SourceServerType {
    func createStatusFromState(state: BuildState, description: String?, targetUrl: [String: String]?) -> StatusType {
        let bbState = BitBucketEnterpriseStatus.BitBucketEnterpriseState.fromBuildState(state: state)
        let key = "Buildasaur"
        return BitBucketEnterpriseStatus(state: bbState, key: key, name: key, description: description, url: targetUrl)
    }

    func getBranchesOfRepo(repo: String, completion: @escaping (_ branches: [BranchType]?, _ error: Error?) -> Void) {

        //TODO: start returning branches
        completion([], nil)
    }

    func getOpenPullRequests(repo: String, completion: @escaping (_ prs: [PullRequestType]?, _ error: Error?) -> Void) {

        let params = [
            "repo": repo
        ]
        self._sendRequestWithMethod(method: .get, endpoint: .PullRequests, params: params, query: nil, body: nil) { (_ response, body, error) -> Void in

            if error != nil {
                completion(nil, error)
                return
            }

            if let body = body as? [NSDictionary] {
                let (prs, error): ([BitBucketEnterprisePullRequest]?, NSError? ) = unthrow {
                    return try BitBucketEnterpriseArray(jsonArray: body)
                }
                prs?.forEach { (pr) in
                    pr.repoName = repo
                }
                completion(prs?.map { $0 as PullRequestType }, error)
            } else {
                completion(nil, GithubServerError.with("Wrong body \(String(describing: body))"))
            }
        }
    }

    func getPullRequest(pullRequestNumber: Int, repo: String, completion: @escaping (_ pr: PullRequestType?, _ error: Error?) -> Void) {

        let params = [
            "repo": repo,
            "pr": pullRequestNumber.description
        ]

        self._sendRequestWithMethod(method: .get, endpoint: .PullRequests, params: params, query: nil, body: nil) { (_ response, body, error) -> Void in

            if error != nil {
                completion(nil, error)
                return
            }

            if let body = body as? NSDictionary {
                let (pr, error): (BitBucketEnterprisePullRequest?, NSError? ) = unthrow {
                    return try BitBucketEnterprisePullRequest(json: body)
                }

                pr?.repoName = repo
                completion(pr, error)
            } else {
                completion(nil, GithubServerError.with("Wrong body \(String(describing: body))"))
            }
        }
    }

    func getRepo(repo: String, completion: @escaping (_ repo: RepoType?, _ error: Error?) -> Void) {
        let repo = service.repoName()
        let params = [
            "repo": repo
        ]

        self._sendRequestWithMethod(method: .get, endpoint: .Repos, params: params, query: nil, body: nil) { (_ response, body, error) -> Void in

            if error != nil {
                completion(nil, error)
                return
            }

            if let body = body as? NSDictionary {
                let (repository, error): (BitBucketEnterpriseRepo?, NSError?) = unthrow {
                    return try BitBucketEnterpriseRepo(json: body)
                }

                completion(repository, error)
            } else {
                completion(nil, GithubServerError.with("Wrong body \(String(describing: body))"))
            }
        }
    }

    func getStatusOfCommit(commit: String, repo: String, completion: @escaping (_ status: StatusType?, _ error: Error?) -> Void) {

        let params = [
            "repo": repo,
            "sha": commit
            ]

        self._sendRequestWithMethod(method: .get, endpoint: .CommitStatuses, params: params, query: nil, body: nil) { (response, body, error) -> Void in

            if response?.statusCode == 404 {
                //no status yet, just pass nil but OK
                completion(nil, nil)
                return
            }

            if error != nil {
                completion(nil, error)
                return
            }

            if let body = body as? NSArray {
                Log.verbose("--------------- getStatusOfCommit: \(body)")
                //TODO: make this use a Array instaed of NSArray so can use isEmpty
                if body.count >= 1 {
                    if let body = body[0] as? NSDictionary {
                        let (status, error): (BitBucketEnterpriseStatus?, NSError?) = unthrow {
                            return try BitBucketEnterpriseStatus(json: body)
                        }

                        completion(status, error)
                        return
                    }
                }
                // No Status
                completion(nil, nil)
                return
            }
            completion(nil, GithubServerError.with("Wrong body \(String(describing: body))"))

        }
    }

    func postStatusOfCommit(commit: String, status: StatusType, repo: String, completion: @escaping (_ status: StatusType?, _ error: Error?) -> Void) {

        let params = [
            "repo": repo,
            "sha": commit
        ]

        let body = (status as! BitBucketEnterpriseStatus).dictionarify()
        self._sendRequestWithMethod(method: .post, endpoint: .CommitStatuses, params: params, query: nil, body: body) { (response, _ body, _ error) -> Void in
            let isSuccessful = response != nil && 200...299 ~= response!.statusCode
            // status is always nil because the server doesn't return it at all
            if isSuccessful {
                completion(nil, nil)
            } else {
                completion(nil, GithubServerError.with("Status code is not 2xx, failed to store status of commit"))
            }
        }
    }

    private func _postCommentOnIssue(comment: String, issueNumber: Int, repo: String, completion: @escaping (_ comment: CommentType?, _ error: Error?) -> Void) {

        let params = [
            "repo": repo,
            "pr": issueNumber.description
        ]

        let body = [
            "text": comment
        ]

        self._sendRequestWithMethod(method: .post, endpoint: .PullRequestComments, params: params, query: nil, body: body as NSDictionary) { (_ response, body, error) -> Void in

            if error != nil {
                Log.verbose("Failed to post comment with error: \(String(describing: error?.localizedDescription))")
                completion(nil, error)
                return
            }

            if let body = body as? NSDictionary {
                let (comment, error): (BitBucketEnterpriseComment?, NSError?) = unthrow {
                    return try BitBucketEnterpriseComment(json: body)
                }

                completion(comment, error)
            } else {
                completion(nil, GithubServerError.with("Wrong body \(String(describing: body))"))
            }
        }
    }

    func getCommentsOfIssue(issueNumber: Int, repo: String, completion: @escaping (_ comments: [CommentType]?, _ error: Error?) -> Void) {

        let params = [
            "repo": repo,
            "pr": issueNumber.description
        ]

        self._sendRequestWithMethod(method: .get, endpoint: .PullRequestComments, params: params, query: nil, body: nil) { (_ response, body, error) -> Void in

            if error != nil {
                completion(nil, error)
                return
            }

            if let body = body as? [NSDictionary] {
                let (comments, error): ([BitBucketEnterpriseComment]?, NSError?) = unthrow {
                    return try BitBucketEnterpriseArray(jsonArray: body)
                }

                completion(comments?.map { $0 as CommentType }, error)
            } else {
                completion(nil, GithubServerError.with("Wrong body \(String(describing: body))"))
            }
        }
    }
    func approvePR(pr number: Int, repo name: String, completion: @escaping ((NSError?) -> Void)) {
        let params = [
            "repo": name,
            "pr": number.description
        ]
        _sendRequestWithMethod(method: .post, endpoint: .ApprovePR, params: params, query: nil, body: nil) { (_ response, _ body, error) in
            completion(error as NSError?)
        }
    }
    func unApprovePR(pr number: Int, repo name: String, completion: @escaping ((NSError?) -> Void)) {
        let params = [
            "repo": name,
            "pr": number.description
        ]
        _sendRequestWithMethod(method: .delete, endpoint: .ApprovePR, params: params, query: nil, body: nil) { (_ response, _ body, error) in
            completion(error as NSError?)
        }
    }
}
extension BitBucketEnterpriseServer: Notifier {
    func postCommentOnIssue(notification: NotifierNotification, completion: @escaping (_ comment: CommentType?, _ error: Error?) -> Void) {
        self._postCommentOnIssue(comment: notification.comment, issueNumber: notification.issueNumber!, repo: notification.repo) { (comment, error) -> Void in
            completion(comment, error)
        }
    }
}
extension BitBucketEnterpriseServer {

    private func _sendRequest(request: NSMutableURLRequest, isRetry: Bool = false, completion: @escaping HTTP.Completion) {
        let cachedInfo = self.cache.getCachedInfoForRequest(request as URLRequest)
        if let etag = cachedInfo.etag {
            request.setValue(etag, forHTTPHeaderField: "If-None-Match")
        }

        _ = self.http.sendRequest(request as URLRequest) { (response, body, error) -> Void in

            if let error = error {
                completion(response, body, error)
                return
            }
            //error out on special HTTP status codes
            let statusCode = response!.statusCode
            switch statusCode {
            case 200...299: //good response, cache the returned data
                let responseInfo = ResponseInfo(response: response!, body: body as AnyObject)
                cachedInfo.update(responseInfo)
            case 304: //not modified, return the cached response
                let responseInfo = cachedInfo.responseInfo!
                completion(responseInfo.response, responseInfo.body, nil)
                return
            case 400 ... 500:
                let message = (((body as? NSDictionary)?["errors"] as? NSArray)?[0] as? NSDictionary)?["message"] as? String ?? (body as? String ?? "Unknown error")
                let resultString = "\(statusCode): \(message)"
                completion(response, body, GithubServerError.with(resultString/*, internalError: error*/))
                return
            default:
                break
            }
            completion(response, body, error)
        }
    }

    private func _sendRequestWithMethod(method: HTTP.Method, endpoint: BitBucketEnterpriseEndpoints.Endpoint, params: [String: String]?, query: [String: String]?, body: NSDictionary?, completion: @escaping HTTP.Completion) {

        var allParams = [
            "method": method.rawValue
        ]

        //merge the two params
        if let params = params {
            for (key, value) in params {
                allParams[key] = value
            }
        }

        do {
            let request = try self.endpoints.createRequest(method: method, endpoint: endpoint, params: allParams, query: query, body: body)
            self._sendRequestWithPossiblePagination(request: request, accumulatedResponseBody: NSArray(), completion: completion)
        } catch {
            completion(nil, nil, GithubServerError.with("Couldn't create Request, error \(error)"))
        }
    }

    private func _sendRequestWithPossiblePagination(request: NSMutableURLRequest, accumulatedResponseBody: NSArray, completion: @escaping HTTP.Completion) {

        self._sendRequest(request: request) { (response, body, error) -> Void in

            if error != nil {
                completion(response, body, error)
                return
            }

            guard let dictBody = body as? NSDictionary else {
                completion(response, body, error)
                return
            }

            //pull out the values
            guard let arrayBody = dictBody["values"] as? [AnyObject] else {
                completion(response, dictBody, error)
                return
            }

            //we do have more, let's fetch it
            let newBody = accumulatedResponseBody.addingObjects(from: arrayBody)

            guard let nextLink = dictBody.optionalStringForKey("next") else {

                //is array, but we don't have any more data
                completion(response, newBody, error)
                return
            }

            let newRequest = request.mutableCopy() as! NSMutableURLRequest
            newRequest.url = URL(string: nextLink)!
            self._sendRequestWithPossiblePagination(request: newRequest, accumulatedResponseBody: newBody as NSArray, completion: completion)
            return
        }
    }

}
