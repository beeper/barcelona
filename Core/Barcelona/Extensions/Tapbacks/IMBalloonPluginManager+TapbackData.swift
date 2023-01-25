//
//  IMBalloonPluginManager+TapbackData.swift
//  imcore-rest
//
//  Created by Eric Rabil on 8/5/20.
//  Copyright © 2020 Eric Rabil. All rights reserved.
//

import Foundation
import IMCore

struct TapbackData {
    var summary: String?
    var pluginDisplayName: String?
}

extension IMBalloonPluginManager {
    static var legalArchiverClasses: [AnyClass] {
        [
               NSString.self,
               NSData.self,
               NSNumber.self,
               NSURL.self,
               NSUUID.self,
               NSValue.self,
               NSMutableDictionary.self,
               NSDictionary.self,
               NSMutableData.self,
               NSMutableString.self,
//               NSClassFromString("RichLink").self!
       ]
    }
    
    /**
     Returns the necessary metadata for a plug-in balloon when doing a tapback on it
     */
    static func extractTapbackInformationForMessage(_ message: IMMessage) -> TapbackData? {
        if let bundleID = message.balloonBundleID {
            var data = TapbackData()
            let manager = sharedInstance()!

            guard let payloadData = message.payloadData else {
                return nil
            }

            let decoded = try? NSKeyedUnarchiver.unarchivedObject(ofClasses: legalArchiverClasses, from: payloadData)
            
            if let dict = decoded as? NSDictionary {
                if let applicationName = dict.value(forKey: "an") as? String {
                    data.pluginDisplayName = applicationName
                    return data
                }
            }
            
            if let source = manager.dataSourceClass(forBundleID: bundleID) as? IMBalloonPluginDataSource.Type {
                data.summary = source.previewSummary(forPluginBundle: bundleID) as? String
                return data
            }
        }
        
        return nil
    }
}
