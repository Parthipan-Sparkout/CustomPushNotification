//
//  NotificationService.swift
//  Service
//
//  Created by Sparkout on 12/04/23.
//

import UserNotifications

class NotificationService: UNNotificationServiceExtension {

    var contentHandler: ((UNNotificationContent) -> Void)?
    var bestAttemptContent: UNMutableNotificationContent?

    override func didReceive(_ request: UNNotificationRequest, withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void) {
        self.contentHandler = contentHandler
        bestAttemptContent = (request.content.mutableCopy() as? UNMutableNotificationContent)
        
        if let bestAttemptContent = bestAttemptContent {
            // Modify the notification content here...
            bestAttemptContent.title = "\(bestAttemptContent.title)"
            print("notification", request.content.userInfo)
            var urlString:String? = nil
            
            if let userInfoDict = request.content.userInfo[AnyHashable("fcm_options")] as? [String:Any], let urlImageString = userInfoDict["image"] as? String {
                urlString = urlImageString
            }
            
            if urlString != nil, let fileUrl = URL(string: urlString!) {
                print("fileUrl: \(fileUrl)")
                
                guard let imageData = NSData(contentsOf: fileUrl) else {
                    contentHandler(bestAttemptContent)
                    return
                }
                guard let attachment = UNNotificationAttachment.saveImageToDisk(fileIdentifier: "image.jpg", data: imageData, options: nil) else {
                    print("error in UNNotificationAttachment.saveImageToDisk()")
                    contentHandler(bestAttemptContent)
                    return
                }
                bestAttemptContent.attachments = [ attachment ]
            }
            contentHandler(bestAttemptContent)
        }
    }
    
    override func serviceExtensionTimeWillExpire() {
        
        if let contentHandler = contentHandler, let bestAttemptContent =  bestAttemptContent {
            contentHandler(bestAttemptContent)
        }
    }
}


extension UNNotificationAttachment {
    
    static func saveImageToDisk(fileIdentifier: String, data: NSData, options: [NSObject : AnyObject]?) -> UNNotificationAttachment? {
        let fileManager = FileManager.default
        let folderName = ProcessInfo.processInfo.globallyUniqueString
        let folderURL = NSURL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(folderName, isDirectory: true)
        
        do {
            try fileManager.createDirectory(at: folderURL!, withIntermediateDirectories: true, attributes: nil)
            let fileURL = folderURL?.appendingPathComponent(fileIdentifier)
            try data.write(to: fileURL!, options: [])
            let attachment = try UNNotificationAttachment(identifier: fileIdentifier, url: fileURL!, options: options)
            return attachment
        } catch let error {
            print("error \(error)")
        }
        
        return nil
    }
}
