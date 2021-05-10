import XCTest
@testable import FeatherClient

final class FeatherClientTests: XCTestCase {
    
    func testExample() {
        
        let expectation = XCTestExpectation(description: "HTTP request")

        let client = FeatherClient(baseUrl: "https://jsonplaceholder.typicode.com", delegate: nil)
        

        let task = client.settings { result in
            defer {
                expectation.fulfill()
            }
            switch result {
            case .success(let response) where 200...299 ~= response.statusCode:
                print("ok")
//                print(response.headers)
//                print(response.content)
            case .success(let response) where 400 == response.statusCode:
                print("ouch")
            case .success(_):
                print("possible error...")
            case .failure(let error):
                print(error)
            }
        }
        task.resume()
        wait(for: [expectation], timeout: 5)
    }
}
