//
//  File.swift
//  
//
//  Created by Tibor Bodecs on 2021. 05. 07..
//

import Foundation

public typealias HTTPResult = Result<HTTP.Response, HTTP.Error>
public typealias HTTPCompletion = (HTTPResult) -> Void

public typealias HTTPContentResult<T: Decodable> = Result<HTTP.Content<T>, HTTP.Error>
public typealias HTTPContentCompletion<T: Decodable> = (HTTPContentResult<T>) -> Void

public enum HTTP {

    public enum Error: LocalizedError {
        case invalidResponse
        case unknown(Swift.Error)
        case decoding(String)
    }

    public enum Method: String {
        case get
        case post
        case put
        case delete
        case patch
        case head
    }

    public enum Header {
        case contentDisposition(String)
        case accept([MIMEType])
        case contentType(MIMEType)
        case authorization(String)
        case custom(String, String)

        public var key: String {
            switch self {
            case .contentDisposition:
                return "Content-Disposition"
            case .accept:
                return "Accept"
            case .contentType:
                return "Content-Type"
            case .authorization:
                return "Authorization"
            case .custom(let key, _):
                return key
            }
        }

        public var value: String {
            switch self {
            case .contentDisposition(let disposition):
                return disposition
            case .accept(let types):
                return types.reduce("") { $0 + ", " + $1.rawValue }
            case .contentType(let type):
                return type.rawValue
            case .authorization(let token):
                return "Bearer \(token)"
            case .custom(_, let value):
                return value
            }
        }
    }

    public enum MIMEType: String {
        case json = "application/json"
    }

    public struct Response {

        public let statusCode: Int
        public let headers: [String: String]
        public let data: Data?
        
        public init(statusCode: Int, headers: [String : String] = [:], data: Data? = nil) {
            self.statusCode = statusCode
            self.headers = headers
            self.data = data
        }

        public var utf8String: String? {
            guard let data = data else {
                return nil
            }
            return String(data: data, encoding: .utf8)
        }
    }

    public struct EmptyContent: Codable {
        public init() {}
    }

    public struct Content<T: Decodable> {
            
        public let statusCode: Int
        public let headers: [String: String]
        public let content: T?
        
        public init(statusCode: Int, headers: [String : String] = [:], content: T? = nil) {
            self.statusCode = statusCode
            self.headers = headers
            self.content = content
        }
    }


    public struct Request {
        public var url: URL
        public var method: Method
        public var headers: [Header] = []
        public var body: Data?

        /// returns an `URLRequest` object
        public var urlRequest: URLRequest {
            var request = URLRequest(url: url)
            request.httpMethod = method.rawValue.uppercased()
            request.httpBody = body

            // Setup request headers
            for header in headers {
                request.addValue(header.value, forHTTPHeaderField: header.key)
            }

            return request
        }

        func dataTask(session: URLSession = .shared, completion: @escaping HTTPCompletion) -> URLSessionDataTask {
            URLSession.shared.dataTask(with: urlRequest) { data, response, error in
                if let error = error {
                    return completion(.failure(.unknown(error)))
                }
                guard let httpResponse = response as? HTTPURLResponse else {
                    return completion(.failure(.invalidResponse))
                }
                var headers: [String: String] = [:]
                for field in httpResponse.allHeaderFields {
                    if let key = field.key as? String, let value = field.value as? String {
                      headers[key] = value
                    }
                }
                return completion(.success(.init(statusCode: httpResponse.statusCode, headers: headers, data: data)))
            }
        }
    }
}
