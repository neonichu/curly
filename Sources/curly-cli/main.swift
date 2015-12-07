import Curly
import Foundation

public enum ContentfulError : ErrorType {
    case InvalidHTTPResponse(response: NSURLResponse?)
    case InvalidURL(string: String)
    case UnparseableJSON(data: NSData, errorMessage: String)
}

import Interstellar

func signalify<T, U, V>(parameter: T, _ closure: (T, (Result<U>) -> ()) -> V) -> (V, Signal<U>) {
    let signal = Signal<U>()
    let value = closure(parameter) { signal.update($0) }
    return (value, signal)
}

class Network {
    var sessionConfigurator: ((HTTPSessionConfiguration) -> ())?

    private var session: HTTPSession {
        let sessionConfiguration = HTTPSessionConfiguration.defaultSessionConfiguration()
        if let sessionConfigurator = sessionConfigurator {
            sessionConfigurator(sessionConfiguration)
        }
        return HTTPSession(configuration: sessionConfiguration)
    }

    func fetch(url: NSURL, _ completion: Result<NSData> -> Void) -> HTTPSessionDataTask {
        let task = session.dataTaskWithURL(url) { (data, response, error) in
            if let data = data {
                completion(.Success(data))
                return
            }

            if let error = error {
                completion(.Error(error))
                return
            }

            completion(.Error(ContentfulError.InvalidHTTPResponse(response: response)))
        }

        task.resume()
        return task
    }

    func fetch(url: NSURL) -> (HTTPSessionDataTask, Signal<NSData>) {
        return signalify(url, fetch)
    }
}

import AppKit

let urlString = Process.arguments.last
let url = NSURL(string: urlString!)

if url == nil || !url!.scheme.hasPrefix("http") {
  print("Usage: \(Process.arguments.first!) url")
  exit(1)
}

NSApplicationLoad()

let network = Network()
network.fetch(url!).1.next { (data) in
    print(NSString(data: data, encoding: NSUTF8StringEncoding)!)
    exit(0)
}.error { (error) in
    print(error)
    exit(1)
}

NSApp.run()
