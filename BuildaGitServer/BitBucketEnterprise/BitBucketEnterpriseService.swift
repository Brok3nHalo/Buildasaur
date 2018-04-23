//
//  BitBucketEnterpriseService.swift
//  Buildasaur
//
//  Created by Chiong, Gianne | Gian | SDTD on 4/19/16.
//  Copyright © 2016 Honza Dvorsky. All rights reserved.
//
import Foundation
import Keys
public struct BitBucketEnterpriseService: GitService {
    public let _baseURL: NSURL
    public init() {
        self.init(baseURL: "")
    }

    public init(baseURL: String) {
        self._baseURL = NSURL(string: baseURL)!
    }

    public func serviceType() -> GitServiceType {
        return .BitBucketEnterprise
    }

    public func prettyName() -> String {
        return "BitBucket Enterprise"
    }

    public func logoName() -> String {
        return "bitbucket"
    }

    public func hostname() -> String {
        return _baseURL.host!
    }

    public func baseURL() -> NSURL {
        return _baseURL
    }

    public func repoName() -> String {
        let pathComponents = _baseURL.pathComponents!
        let serviceRepoName = "\(pathComponents[1])/\(pathComponents[2].components(separatedBy: ".")[0])"
        return serviceRepoName
    }

    public func authorizeUrl() -> String {
        return ""
    }

    public func accessTokenUrl() -> String {
        return ""
    }

    public func serviceKey() -> String {

        return BuildasaurKeys().bitBucketEnterpriseUsername
    }

    public func serviceSecret() -> String {
        return BuildasaurKeys().bitBucketEnterprisePassword
    }

}
