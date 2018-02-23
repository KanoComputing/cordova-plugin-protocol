class ContentURLProtocol: URLProtocol {
    static var scheme = "protocol-plugin"
    static var root = "www"
    static let bufferSize = 4096

    override class func canInit(with request: URLRequest) -> Bool {
        // Debugging
        // print("Request URL = \(request.url!)")

        if request.url!.scheme == self.scheme {
            //print("Will handle \(request.url!)")
            return true
        }

        return false
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        return request
    }

    override func startLoading() {
        if let url = self.request.url {
            let urlString = url.absoluteString

            // remove the leading SCHEME:// from the URL
            let startIndex = urlString.index(urlString.startIndex, offsetBy: "\(ContentURLProtocol.scheme)://".count)
            let endIndex = urlString.endIndex
            var filePath = urlString[startIndex..<endIndex]

            let wwwPath = "\(Bundle.main.bundlePath)/\(ContentURLProtocol.root)"
            let mimeType = MimeType(url: url).value
            let response = URLResponse(
                url: url,
                mimeType: mimeType,
                expectedContentLength: -1,
                textEncodingName: nil
            )

            // Load index.html by default
            if filePath == "" || filePath == "/" {
                filePath = "/index.html"
            }

            // debugging purposes
            //print("Loading \(wwwPath)\(filePath) \(mimeType)")

            if let stream:InputStream = InputStream(fileAtPath: "\(wwwPath)\(filePath)") {
                let bufferSize = ContentURLProtocol.bufferSize
                let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: bufferSize)

                if let client = self.client {
                    client.urlProtocol(self, didReceive: response, cacheStoragePolicy: URLCache.StoragePolicy.notAllowed)

                    stream.open()
                    while stream.hasBytesAvailable {
                        let len = stream.read(buffer, maxLength: bufferSize)

                        // File not found, fail
                        if len == -1 {
                            client.urlProtocol(self, didFailWithError: stream.streamError!)
                            buffer.deallocate(capacity: bufferSize)
                            stream.close()
                            return
                        }

                        // End of buffer
                        if len == 0 {
                            break
                        }

                        // Forward chunk to client
                        client.urlProtocol(self, didLoad: Data(bytes: buffer, count: Int(len)))
                    }
                    buffer.deallocate(capacity: bufferSize)
                    stream.close()
                    client.urlProtocolDidFinishLoading(self)
                }
            }
        }
    }

    override func stopLoading() {

    }
}


@objc(ProtocolPlugin) class ProtocolPlugin : CDVPlugin {
    override func pluginInitialize() {
        if let scheme = self.commandDelegate.settings["Scheme".lowercased()] as? String {
            ContentURLProtocol.scheme = scheme
        }
        if let root = self.commandDelegate.settings["Root".lowercased()] as? String {
            ContentURLProtocol.root = root
        }

        URLProtocol.registerClass(ContentURLProtocol.self)
    }
}

