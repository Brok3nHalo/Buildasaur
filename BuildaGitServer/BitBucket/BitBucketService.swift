//
//  BitBucketService.swift
//  Buildasaur
//
//  Created by Chiong, Gianne | Gian | SDTD on 4/19/16.
//  Copyright © 2016 Honza Dvorsky. All rights reserved.
//

import Foundation
import Keys

public struct BitBucketService: GitService {

    public init() {
    }

    public func serviceType() -> GitServiceType {
        return .BitBucket
    }

    public func prettyName() -> String {
        return "BitBucket"
    }

    public func logoName() -> String {
        return "bitbucket"
    }

    public func hostname() -> String {
        return baseURL().host!
    }

    public func baseURL() -> NSURL {
        return NSURL(string: "http://bitbucket.org")!
    }

    public func authorizeUrl() -> String {
        return "https://bitbucket.org/site/oauth2/authorize"
    }

    public func accessTokenUrl() -> String {
        return "https://bitbucket.org/site/oauth2/access_token"
    }

    public func serviceKey() -> String {
        return BuildasaurKeys().bitBucketAPIClientId
    }

    public func serviceSecret() -> String {
        return BuildasaurKeys().bitBucketAPIClientSecret
    }
}
