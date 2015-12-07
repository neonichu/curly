#if os(Linux)
import Glibc

func async(block: (Void) -> Void) {
  block()
}
#else
import Dispatch

func async(block: (Void) -> Void) {
  dispatch_async(dispatch_get_global_queue(QOS_CLASS_BACKGROUND, 0), block)
}
#endif

func read_stdout(bufferSize: Int = 1024, block: (Void) -> Void) -> String? {
  var buffer = UnsafeMutablePointer<Int8>.alloc(bufferSize)
  var output_pipe = UnsafeMutablePointer<Int32>.alloc(2)
  let saved_stdout = dup(STDOUT_FILENO)

  if pipe(output_pipe) < 0 {
    fatalError("Could not create pipe")
  }

  setbuf(stdout, nil)
  dup2(output_pipe[1], STDOUT_FILENO)
  close(output_pipe[1])

  block()

  read(output_pipe[0], buffer, bufferSize)
  let result = String.fromCString(buffer)

  dup2(saved_stdout, STDOUT_FILENO)
  buffer = nil
  output_pipe = nil

  return result
}
