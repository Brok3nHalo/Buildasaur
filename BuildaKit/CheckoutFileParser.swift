//
//  CheckoutFileParser.swift
//  Buildasaur
//
//  Created by Honza Dvorsky on 10/21/15.
//  Copyright © 2015 Honza Dvorsky. All rights reserved.
//

import Foundation
import BuildaUtils

class CheckoutFileParser: SourceControlFileParser {

    func supportedFileExtensions() -> [String] {
        return ["xccheckout"]
    }

    func parseFileAtUrl(url: URL) throws -> WorkspaceMetadata {

        //plist -> NSDictionary
        guard let dictionary = NSDictionary(contentsOf: url) else { throw XcodeDeviceParserError.with("Failed to parse \(url)") }

        //parse our required keys
        let projectName = dictionary.optionalStringForKey("IDESourceControlProjectName")
        let projectPath = dictionary.optionalStringForKey("IDESourceControlProjectPath")
        let projectWCCIdentifier = dictionary.optionalStringForKey("IDESourceControlProjectWCCIdentifier")
        let projectWCCName = { () -> String? in
            if let wccId = projectWCCIdentifier {
                if let wcConfigs = dictionary["IDESourceControlProjectWCConfigurations"] as? [NSDictionary] {
                    if let foundConfig = wcConfigs.first(where: {
                        if let loopWccId = $0.optionalStringForKey("IDESourceControlWCCIdentifierKey") {
                            return loopWccId == wccId
                        }
                        return false
                    }) {
                        //so much effort for this little key...
                        return foundConfig.optionalStringForKey("IDESourceControlWCCName")
                    }
                }
            }
            return nil
            }()
        let projectURLString = { dictionary.optionalStringForKey("IDESourceControlProjectURL") }()

        return try WorkspaceMetadata(projectName: projectName, projectPath: projectPath, projectWCCIdentifier: projectWCCIdentifier, projectWCCName: projectWCCName, projectURLString: projectURLString)
    }
}
