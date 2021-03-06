//
//  Director.swift
//  SwiftWebServer
//
//  Created by OOPer in cooperation with shlab.jp, on 2015/5/3.
//  Copyright (c) 2015 OOPer (NAGATA, Atsuyuki). All rights reserved.
//

import Foundation

protocol Director {
    init(request: HTTPRequest, response: HTTPResponse)
    
    func direct()
}

class ChiefDirector: Director {
    var request: HTTPRequest
    var response: HTTPResponse
    class func findDirector(request: HTTPRequest, _ response: HTTPResponse) -> Director {
        return ChiefDirector(request: request, response: response)
    }
    
    required init(request: HTTPRequest, response: HTTPResponse) {
        self.request = request
        self.response = response
    }

    private func send(message: String) {
        response.transmitter.send(message)
    }
    func direct() {
        let host = request.headers["host"]
        let url = NSURL(scheme: "http", host: host, path: request.path!)!
        print("url=\(url)")
        var documentURL = Options.instance.staticBaseURL.URLByAppendingPathComponent(request.path!)
        let fileManager = NSFileManager.defaultManager()
        var isDirectory: ObjCBool = false
        if fileManager.fileExistsAtPath(documentURL.path!, isDirectory: &isDirectory) {
            if isDirectory {
                for file in Options.instance.defaults {
                    let fileURL = documentURL.URLByAppendingPathComponent(file)
                    if fileManager.fileExistsAtPath(fileURL.path!, isDirectory: &isDirectory) && !isDirectory {
                        documentURL = fileURL
                        break
                    }
                }
            }
            print("documentURL=\(documentURL)")
            if let fileData = NSData(contentsOfURL: documentURL) {
                let ext = documentURL.pathExtension ?? ""
                if let type = Options.instance.types[ext] {
                    response.contentType = type
                } else {
                    response.contentType = "application/octet-stream"
                }
                response.contentLength = fileData.length
                response.sendHeaders()
                response.transmitter.send(fileData)
                response.transmitter.close()
                return
            }
        }
        //
        NSLog("sending response")
        response.contentType = "text/html"
        response.status = HTTPStatus.NotFound
        response.sendHeaders()
        send("<h1>\(response.status.fullDescription)</h1>\r\n")
        send("The requested resource \(request.path!) was not found on this server.<br>\r\n")
        response.transmitter.close()
        
    }
}
