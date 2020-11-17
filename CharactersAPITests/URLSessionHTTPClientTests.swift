//
//  URLSessionHTTPClientTests.swift
//  CharactersAPITests
//
//  Created by Hugo Alonso on 16/11/2020.
//

import XCTest
import Foundation
import CommonCrypto

final class APIConfig {
    private let itemsPerPage = 20
    private let privateAPIKey = "da9b58ab629e94bb1d66ea165fe1fe92c896ba08"
    private let publicAPIKey = "19972fbcfc8ba75736070bc42fbca671"

    private var urlComponents: URLComponents

    init?(url: URL) {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            return nil
        }
        urlComponents = components
    }

    func resolve(for page: Int = 0) -> URL? {
        urlComponents.queryItems = params(for: page).map(URLQueryItem.init)
        return urlComponents.url
    }

    private func pagination(for page: Int) -> (offset: Int, limit: Int) {
        (offset: page * itemsPerPage, limit : itemsPerPage)
    }

    func params(for page: Int = 0) -> [String: String] {
        let (offset, limit) = pagination(for: max(page, 0))
        let timestamp = Date.timeIntervalSinceReferenceDate.description
        return [
            "apikey": publicAPIKey,
            "hash" : MD5Digester.createHash(timestamp, privateAPIKey, publicAPIKey),
            "ts" : timestamp,
            "limit" : limit.description,
            "offset" : offset.description,
        ]
    }

    private struct MD5Digester {

        static func createHash(_ values: String...) -> String {
            digest(values.joined())
        }

        // return MD5 digest of string provided
        private static func digest(_ string: String) -> String {

            guard let data = string.data(using: String.Encoding.utf8) else { return "" }

            var digest = [UInt8](repeating: 0, count: Int(CC_MD5_DIGEST_LENGTH))

            CC_MD5((data as NSData).bytes, CC_LONG(data.count), &digest)

            return (0..<Int(CC_MD5_DIGEST_LENGTH)).reduce("") { $0 + String(format: "%02x", digest[$1]) }
        }
    }
}

class URLSessionHTTPClient {
    let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    func get(from url: URL, completion: @escaping (Result<(Data, HTTPURLResponse), Error>) -> Void) {
        session.dataTask(with: url) { data, response, error in
            if let error = error {
                completion(.failure(error))
            }
            if let data = data, let response = response as? HTTPURLResponse {
                completion(.success((data, response)))
            }
        }.resume()
    }
}

class URLSessionHTTPClientTests: XCTestCase {

    func test_load_onFailure_FailsWithError() {
        URLProtocolStub.startIntercepting()
        let expectedError = NSError(domain: "anyerror", code: 123, userInfo: nil)
        let sut = URLSessionHTTPClient()
        let url = URL(string: "www.url.com")!
        URLProtocolStub.stub(url: url, data: nil, response: nil, error: expectedError)

        let expect = expectation(description: "Waiting for expectation")

        sut.get(from: url) { result in
            switch result {
            case .success:
                XCTFail()
            case let .failure(receivedError as NSError):
                XCTAssertEqual(expectedError.domain, receivedError.domain)
                XCTAssertEqual(expectedError.code, receivedError.code)
            }
            expect.fulfill()
        }
        wait(for: [expect], timeout: 1)
        URLProtocolStub.stopIntercepting()
    }

    func test_load_DataFromNetwork() {
        let sut = URLSessionHTTPClient()
        let url = URL(string: "https://gateway.marvel.com:443/v1/public/characters")!

        let enhancedURL = APIConfig(url: url)!.resolve()!

        let expect = expectation(description: "Waiting for \(enhancedURL) to resolve")

        sut.get(from: enhancedURL) { result in
            switch result {
            case let .success(data, response):
                XCTAssertEqual(response.statusCode, 200)
            case let .failure(receivedError as NSError):
                XCTFail(receivedError.description)
            }
            expect.fulfill()
        }
        wait(for: [expect], timeout: 30)
    }
}

private class URLProtocolStub: URLProtocol {
    private static var stubs =  [URL: Stub]()

    private struct Stub {
        let data: Data?
        let response: URLResponse?
        let error: Error?
    }

    static func stub(url: URL, data: Data?, response: URLResponse?, error: Error? = nil) {
        Self.stubs[url] = Stub(data: data, response: response, error: error)
    }

    static func startIntercepting() {
        URLProtocol.registerClass(URLProtocolStub.self)
    }

    static func stopIntercepting() {
        URLProtocol.unregisterClass(URLProtocolStub.self)
        stubs = [:]
    }

    override class func canInit(with request: URLRequest) -> Bool {
        guard let url = request.url, Self.stubs[url] != nil else {
            return false
        }
        return true
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        return request
    }

    override func startLoading() {
        guard let url = request.url, let stub = Self.stubs[url] else {
            return
        }

        if let data = stub.data {
            client?.urlProtocol(self, didLoad: data)
        }

        if let response = stub.response {
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        }

        if let error = stub.error {
            client?.urlProtocol(self, didFailWithError: error)
        }
        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {
    }
}
