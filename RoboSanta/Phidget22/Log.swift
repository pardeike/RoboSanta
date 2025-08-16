import Foundation
//import Phidget22

/**
The Phidget Log class is used to track and store information about the opperation of programs using the Phidget22 library.

For basic use of the log class, the only functions you need to worry about are **Enable** and **Log**. Simply **Enable** logging with log level **INFO**, and use **Log** to log your own messages to the log file.

For a more in-depth explanation of the concepts behind the more obscure funcitons, check out the [Logging Explained](/docs/Logging_Explained) page.
*/
public class Log: LogBase {
	
	/**
	Returns a list of log sources in the system
	
	- returns:
	The source names
	
	- throws:
	An error or type `PhidgetError`
	*/
	public static func getSources() throws -> [String] {
		
		let result: PhidgetReturnCode
		let sourcesArr: UnsafeMutablePointer<UnsafePointer<CChar>?> = UnsafeMutablePointer<UnsafePointer?>.allocate(capacity: 256)
		var sourcesArrLen: UInt32 = 256
		result = PhidgetLog_getSources(sourcesArr, &sourcesArrLen)
		if result != EPHIDGET_OK {
			sourcesArr.deallocate()
			throw (PhidgetError(code: result))
		}
		var sources = [String]()
		for str in UnsafeBufferPointer(start: sourcesArr, count: Int(sourcesArrLen)) {
			sources.append(String(cString: str!))
		}
		sourcesArr.deallocate()
		return sources
	}

}
