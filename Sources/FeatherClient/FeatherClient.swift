//
//  File.swift
//
//
//  Created by Tibor Bodecs on 2021. 05. 07..
//

import Foundation
import FeatherApi

public protocol FeatherClientDelegate: AnyObject {

    var token: String? { get set }
}

open class FeatherClient {

    enum Error: LocalizedError {
        case unauthorized
        case notFound
        case response
    }

    public let baseUrl: String

    public weak var delegate: FeatherClientDelegate?

    public init(baseUrl: String, delegate: FeatherClientDelegate? = nil) {
        self.baseUrl = baseUrl
        self.delegate = delegate
    }

    open var encoder: (() -> JSONEncoder) = {
        let encoder = JSONEncoder()
        return encoder
    }

    open var decoder: (() -> JSONDecoder) = {
        let decoder = JSONDecoder()
        return decoder
    }

    // MARK: - internal helpers

    func query(path: String, queryParameters: [URLQueryItem] = [], fragment: String? = nil) -> URL {
        guard var components = URLComponents(string: baseUrl) else {
            fatalError("Invalid base url")
        }
        components.path += path.hasPrefix("/") ? path : "/" + path
        components.fragment = fragment
        components.queryItems = queryParameters

        if let items = components.queryItems, items.isEmpty {
            components.queryItems = nil
        }

        guard let url = components.url else {
            fatalError("invalid url")
        }
        return url
    }

    func dataTask(session: URLSession = .shared,
                  method: HTTP.Method = .get,
                  path: String,
                  headers: [HTTP.Header] = [],
                  queryParameters: [URLQueryItem] = [],
                  body: Data? = nil,
                  completion: @escaping HTTPCompletion) -> URLSessionDataTask
    {
        let url = query(path: path, queryParameters: queryParameters)
        let request = HTTP.Request(url: url, method: method, headers: headers, body: body)
        return request.dataTask(session: session, completion: completion)
    }

    func dataTask<T, U>(_ input: U.Type,
                        session: URLSession = .shared,
                        method: HTTP.Method = .get,
                        path: String,
                        headers: [HTTP.Header] = [],
                        queryParameters: [URLQueryItem] = [],
                        body: U? = nil,
                        completion: @escaping HTTPContentCompletion<T>) -> URLSessionDataTask where T: Decodable, U: Encodable {

        var encodedBody: Data? = nil
        if body != nil {
            encodedBody = try! encoder().encode(body!)
        }
        return dataTask(session: session,
                        method: method,
                        path: path,
                        headers: headers,
                        queryParameters: queryParameters,
                        body: encodedBody) { [unowned self] result in
            
            switch result {
                case .success(let response):
                    do {
                        var content: T? = nil
                        if let data = response.data {
                            content = try decoder().decode(T.self, from: data)
                        }
                        return completion(.success(.init(statusCode: response.statusCode, headers: response.headers, content: content)))
                    }
                    catch {
                        return completion(.failure(.decoding(error.localizedDescription)))
                    }
                case .failure(let error):
                    return completion(.failure(error))
            }
        }
    }


    // MARK: - Public functions

    struct Todo: Decodable {
        let title: String
    }
    
    func settings(completion: @escaping HTTPContentCompletion<[Todo]>) -> URLSessionDataTask {
        dataTask(HTTP.EmptyContent.self, path: "todos", headers: [.contentType(.json)], completion: completion)
    }
    
    func variables(completion: @escaping HTTPContentCompletion<[VariableListObject]>) -> URLSessionDataTask {
        dataTask(HTTP.EmptyContent.self, path: "variables", headers: [.contentType(.json)], completion: completion)
    }
}
