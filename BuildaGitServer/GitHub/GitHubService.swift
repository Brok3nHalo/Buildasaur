//
//  GitHubService.swift
//  Buildasaur
//
//  Created by Chiong, Gianne | Gian | SDTD on 4/19/16.
//  Copyright © 2016 Honza Dvorsky. All rights reserved.
//

import Foundation
import Keys

public struct GitHubService: GitService {

    public init() {

    }

    public func serviceType() -> GitServiceType {
        return .GitHub
    }

    public func prettyName() -> String {
        return "GitHub"
    }

    public func logoName() -> String {
        return "github"
    }

    public func hostname() -> String {
        return baseURL().host!
    }

    public func baseURL() -> NSURL {
        return NSURL(string: "http://github.com")!
    }

    public func authorizeUrl() -> String {
        return "https://github.com/login/oauth/authorize"
    }

    public func accessTokenUrl() -> String {
        return "https://github.com/login/oauth/access_token"
    }

    public func serviceKey() -> String {
        return BuildasaurKeys().gitHubAPIClientId
    }

    public func serviceSecret() -> String {
        return BuildasaurKeys().gitHubAPIClientSecret
    }
}
