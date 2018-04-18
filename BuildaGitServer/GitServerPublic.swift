//
//  GitSourcePublic.swift
//  Buildasaur
//
//  Created by Honza Dvorsky on 12/12/2014.
//  Copyright (c) 2014 Honza Dvorsky. All rights reserved.
//

import Foundation
import BuildaUtils
import Keys

public enum GitService: String {
    case GitHub = "github"
    case BitBucket = "bitbucket"

    public func prettyName() -> String {
        switch self {
        case .GitHub: return "GitHub"
        case .BitBucket: return "BitBucket"
        }
    }

    public func logoName() -> String {
        switch self {
        case .GitHub: return "github"
        case .BitBucket: return "bitbucket"
        }
    }

    public func hostname() -> String {
        switch self {
        case .GitHub: return "github.com"
        case .BitBucket: return "bitbucket.org"
        }
    }

    public func authorizeUrl() -> String {
        switch self {
        case .GitHub: return "https://github.com/login/oauth/authorize"
        case .BitBucket: return "https://bitbucket.org/site/oauth2/authorize"
        }
    }

    public func accessTokenUrl() -> String {
        switch self {
        case .GitHub: return "https://github.com/login/oauth/access_token"
        case .BitBucket: return "https://bitbucket.org/site/oauth2/access_token"
        }
    }

    public func serviceKey() -> String {
        switch self {
        case .GitHub: return BuildasaurKeys().gitHubAPIClientId
        case .BitBucket: return BuildasaurKeys().bitBucketAPIClientId
        }
    }

    public func serviceSecret() -> String {
        switch self {
        case .GitHub: return BuildasaurKeys().gitHubAPIClientSecret
        case .BitBucket: return BuildasaurKeys().bitBucketAPIClientSecret
        }
    }
}

public class GitServer: HTTPServer {

    let service: GitService

    init(service: GitService, http: HTTP? = nil) {
        self.service = service
        super.init(http: http)
    }
}

public class GithubServerError: Error {
    static func with(_ info: String) -> Error {
        return NSError(domain: "GithubServer", code: -1, userInfo: ["info": info])
    }
}
