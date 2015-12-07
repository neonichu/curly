import curl
import Foundation

// FIXME: This is exploiting undefined behaviour to call a variadic C function
/*@_silgen_name("curl_easy_setopt") private func curl_setopt_int(curl: UnsafeMutablePointer<Void>,
    _ option: CURLoption, _ value: Int)
@_silgen_name("curl_easy_setopt") private func curl_setopt_pointer(curl: UnsafeMutablePointer<Void>,
    _ option: CURLoption, _ pointer: UnsafeMutablePointer<Void>)*/
@_silgen_name("curl_easy_setopt") private func curl_setopt_string(curl: UnsafeMutablePointer<Void>,
    _ option: CURLoption, _ string: String)

public class HTTPSessionConfiguration {
  public class func defaultSessionConfiguration() -> HTTPSessionConfiguration {
    return HTTPSessionConfiguration()
  }
}

public typealias HTTPCompletionFunc = ((NSData?, NSURLResponse?, NSError?) -> Void)

public class HTTPSessionDataTask {
  let completion: HTTPCompletionFunc
  let curl = curl_easy_init()
  let URL: NSURL

  private init(URL: NSURL, completion: HTTPCompletionFunc) {
  	self.completion = completion
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

  	//curl_setopt_int(curl, CURLOPT_VERBOSE, 1)
    curl_setopt_string(curl, CURLOPT_URL, URL.absoluteString)

    let result = read_stdout() {
      let _ = curl_easy_perform(self.curl)
    }

    if let result = result, data = result.dataUsingEncoding(NSUTF8StringEncoding) {
      let response = NSURLResponse(URL: URL, MIMEType: nil,
      	expectedContentLength: data.length, textEncodingName: nil)
      completion(data, response, nil)
    } else {
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
    return HTTPSessionDataTask(URL: url, completion: completion)
  }
}
