import curl
import Foundation

#if os(Linux)
import Glibc

extension String {
  func dataUsingEncoding(encoding: UInt) -> NSData? {
    self.withCString { (bytes) in
      return NSData(bytes: bytes, length: Int(strlen(bytes)))
    }
    return nil
  }
}
#endif

// FIXME: This is exploiting undefined behaviour to call a variadic C function
/*@_silgen_name("curl_easy_setopt") private func curl_setopt_int(curl: UnsafeMutablePointer<Void>,
    _ option: CURLoption, _ value: Int)*/
@_silgen_name("curl_easy_setopt") private func curl_setopt_pointer(curl: UnsafeMutablePointer<Void>,
    _ option: CURLoption, _ pointer: UnsafeMutablePointer<Void>)

public class HTTPSessionConfiguration {
  public var HTTPAdditionalHeaders = [String:String]()

  public class func defaultSessionConfiguration() -> HTTPSessionConfiguration {
    return HTTPSessionConfiguration()
  }
}

public typealias HTTPCompletionFunc = ((NSData?, NSURLResponse?, NSError?) -> Void)

public class HTTPSessionDataTask {
  let completion: HTTPCompletionFunc
  let configuration: HTTPSessionConfiguration
  let curl = curl_easy_init()
  let URL: NSURL

  private init(configuration: HTTPSessionConfiguration, URL: NSURL, completion: HTTPCompletionFunc) {
    self.completion = completion
    self.configuration = configuration
    self.URL = URL
  }

  deinit {
    curl_easy_cleanup(curl)
  }

  private var error: NSError {
    return NSError(domain:"org.vu0.curly", code: 23, userInfo: nil)
  }

  private func perform() {
    if curl == nil {
      completion(nil, nil, error)
      return
    }

#if os(Linux)
    let urlString = URL.absoluteString!
#else
    let urlString = URL.absoluteString
#endif

    //curl_setopt_int(curl, CURLOPT_VERBOSE, 1)
    urlString.withCString { (data) -> Void in
      curl_setopt_pointer(self.curl, CURLOPT_URL, UnsafeMutablePointer<Void>(data))
    }

    var headers: UnsafeMutablePointer<curl_slist> = nil
    for header in configuration.HTTPAdditionalHeaders {
      headers = curl_slist_append(headers, "\(header.0): \(header.1)")
    }
    curl_setopt_pointer(curl, CURLOPT_HTTPHEADER, headers)

    var perform_result: CURLcode = CURLcode(0)
    let result = read_stdout() {
      perform_result = curl_easy_perform(self.curl)
    }

    if let result = result, data = result.dataUsingEncoding(NSUTF8StringEncoding) {
      let response = NSURLResponse(URL: URL, MIMEType: nil,
        expectedContentLength: data.length, textEncodingName: nil)
      completion(data, response, nil)
    } else {
      print(perform_result)
      completion(nil, nil, error)
    }
  }

  public func resume() {
    async { self.perform() }
  }
}

public class HTTPSession {
  let configuration: HTTPSessionConfiguration

  public init(configuration: HTTPSessionConfiguration) {
    self.configuration = configuration
  }

  public func dataTaskWithURL(url: NSURL, completion: HTTPCompletionFunc) -> HTTPSessionDataTask {
    return HTTPSessionDataTask(configuration: configuration, URL: url, completion: completion)
  }
}
