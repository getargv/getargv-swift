import Cgetargv
import Foundation
import System

@available(macOS 11, *)
public class PrintableArgvResult {
    var res: ArgvResult;
    init() {
        res = ArgvResult();
    }

    deinit {
        if (res.buffer != nil) { free(res.buffer) }
    }

    public func print() -> Result<Void,Errno> {
        if !print_argv_of_pid(res.start_pointer, res.end_pointer) {
            return .failure(Errno(rawValue: errno))
        } else {
            return .success(())
        }
    }
    public var array: Array<CChar> {
        get { return Array(buffer) }
    }
    public var buffer: UnsafeBufferPointer<CChar> {
        get { return UnsafeBufferPointer<CChar>(start: res.start_pointer!, count: res.end_pointer - res.start_pointer + 1) }
    }
}

@available(macOS 11, *)
public func GetArgvOfPid(pid: pid_t, skip: uint = 0, nuls: Bool = false) -> Result<PrintableArgvResult, Errno> {
    let options = GetArgvOptions(skip:skip, pid:pid, nuls:nuls)
    let res = PrintableArgvResult();
    if (!withUnsafePointer(to: options, { get_argv_of_pid($0, &res.res) })) { return .failure(Errno(rawValue: errno)) }
    return .success(res)
}

@available(macOS 11, *)
public func GetArgvAndArgcOfPid(pid: pid_t) -> Result<Array<String>, Errno> {
    var res = ArgvArgcResult();
    if (!get_argv_and_argc_of_pid(pid, &res)) { return .failure(Errno(rawValue: errno)) }

    defer{free(res.argv)}
    defer{free(res.buffer)}

    return .success(Array(UnsafeBufferPointer<UnsafeMutablePointer<CChar>?>(start: res.argv, count: Int(res.argc))).map { String(cString: $0!) })
}
