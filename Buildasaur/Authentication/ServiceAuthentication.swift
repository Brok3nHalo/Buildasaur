//
//  ServiceAuthentication.swift
//  Buildasaur
//
//  Created by Honza Dvorsky on 1/26/16.
//  Copyright © 2016 Honza Dvorsky. All rights reserved.
//

import Foundation
import OAuthSwift
import BuildaGitServer

class ServiceAuthenticator {

    private var oauth: OAuth2Swift?

    enum ParamKey: String {
        case ConsumerId
        case ConsumerSecret
        case AuthorizeUrl
        case AccessTokenUrl
        case ResponseType
        case CallbackUrl
        case Scope
        case State
    }

    typealias SecretFromResponseParams = ([String: Any]) -> String?

    init() {}

    func handleUrl(_ url: URL) {
        OAuthSwift.handle(url: url)
    }

    func getAccess(_ service: GitService, completion: @escaping (_ auth: ProjectAuthenticator?, _ error: Error?) -> Void) {

        let (params, secretFromResponseParams) = self.paramsForService(service)

        self.oauth = OAuth2Swift(
            consumerKey: params[.ConsumerId]!,
            consumerSecret: params[.ConsumerSecret]!,
            authorizeUrl: params[.AuthorizeUrl]!,
            accessTokenUrl: params[.AccessTokenUrl]!,
            responseType: params[.ResponseType]!
        )
        self.oauth?.authorize(withCallbackURL:
            URL(string: params[.CallbackUrl]!)!,
                              scope: params[.Scope]!,
                              state: params[.State]!,
                              success: { _, _, parameters in

                guard let secret = secretFromResponseParams(parameters) else {
                    completion(nil, nil)
                    return
                }

                let auth = ProjectAuthenticator(service: service, username: "GIT", type: .OAuthToken, secret: secret)
                completion(auth, nil)
            },
            failure: { error in
                completion(nil, error)
            }
        )
    }

    func getAccessTokenFromRefresh(_ service: GitService, refreshToken: String, completion: (auth: ProjectAuthenticator?, error: Error?)) {
        //TODO: implement refresh token flow - to get and save a new access token
    }

    private func paramsForService(_ service: GitService) -> ([ParamKey: String], SecretFromResponseParams) {
        switch service.serviceType() {
        case .GitHub:
            return self.getGitHubParameters()
        case .BitBucket:
            return self.getBitBucketParameters()
        default:
            fatalError()
        }
    }

    private func getGitHubParameters() -> ([ParamKey: String], SecretFromResponseParams) {
        let service = GitHubService()
        let params: [ParamKey: String] = [
            .ConsumerId: service.serviceKey(),
            .ConsumerSecret: service.serviceSecret(),
            .AuthorizeUrl: service.authorizeUrl(),
            .AccessTokenUrl: service.accessTokenUrl(),
            .ResponseType: "code",
            .CallbackUrl: "buildasaur://oauth-callback/github",
            .Scope: "repo",
            .State: generateState(withLength: 20) as String
        ]
        let secret: SecretFromResponseParams = {
            //just pull out the access token, that's all we need
            return $0["access_token"] as? String
        }
        return (params, secret)
    }

    private func getBitBucketParameters() -> ([ParamKey: String], SecretFromResponseParams) {
        let service = BitBucketService()
        let params: [ParamKey: String] = [
            .ConsumerId: service.serviceKey(),
            .ConsumerSecret: service.serviceSecret(),
            .AuthorizeUrl: service.authorizeUrl(),
            .AccessTokenUrl: service.accessTokenUrl(),
            .ResponseType: "code",
            .CallbackUrl: "buildasaur://oauth-callback/bitbucket",
            .Scope: "pullrequest",
            .State: generateState(withLength: 20) as String
        ]
        let secret: SecretFromResponseParams = {
            //we need both the access and refresh tokens, because
            //the refresh token only lives for one hour.
            //but we'll only store the
            let refreshToken = $0["refresh_token"]!
            let accessToken = $0["access_token"]!
            return "\(refreshToken):\(accessToken)"
        }
        return (params, secret)
    }

}
