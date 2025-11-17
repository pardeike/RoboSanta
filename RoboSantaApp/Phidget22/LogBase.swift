import Foundation
//import Phidget22

/**
The Phidget Log class is used to track and store information about the operation of programs using the Phidget22 library.

For basic use of the log class, the only functions you need to worry about are **Enable** and **Log**. Simply **Enable** logging with log level **INFO**, and use **Log** to log your own messages to the log file.

For a more in-depth explanation of the concepts behind the more obscure functions, check out the [Logging Explained](/docs/Logging_Explained) page.
*/
public class LogBase {


	/**
	Disables logging within the Phidget library.

	- throws:
	An error or type `PhidgetError`
	*/
	public static func disable() throws {
		let result: PhidgetReturnCode
		result = PhidgetLog_disable()
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
	}

	/**
	Enables logging within the Phidget library.

	- throws:
	An error or type `PhidgetError`

	- parameters:
		- level: The logging level
		- destination: The log file path, or `NULL` for `STDOUT`
	*/
	public static func enable(level: LogLevel, destination: String? = nil) throws {
		let result: PhidgetReturnCode
		result = PhidgetLog_enable(Phidget_LogLevel(level.rawValue), destination)
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
	}

	/**
	Gets the log level for the phidget22 source.

	- returns:
	The current log level

	- throws:
	An error or type `PhidgetError`
	*/
	public static func getLevel() throws -> LogLevel {
		let result: PhidgetReturnCode
		var level: Phidget_LogLevel = PHIDGET_LOG_CRITICAL
		result = PhidgetLog_getLevel(&level)
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
		return LogLevel(rawValue: level.rawValue)!
	}

	/**
	Sets the log level for all sources not prefaced with _phidget22.

	- throws:
	An error or type `PhidgetError`

	- parameters:
		- level: The new log level
	*/
	public static func setLevel(level: LogLevel) throws {
		let result: PhidgetReturnCode
		result = PhidgetLog_setLevel(Phidget_LogLevel(level.rawValue))
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
	}

	/**
	Writes a message to the Phidget library log.

	- throws:
	An error or type `PhidgetError`

	- parameters:
		- level: The logging level
		- message: The message
	*/
	public static func log(level: LogLevel, message: String) throws {
		let result: PhidgetReturnCode
		result = PhidgetLog_logs(Phidget_LogLevel(level.rawValue), message)
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
	}

	/**
	Writes a message to the Phidget library log with a specified source.

	- throws:
	An error or type `PhidgetError`

	- parameters:
		- level: The logging level
		- source: The name of the log source the message is from
		- message: The message
	*/
	public static func log(level: LogLevel, source: String, message: String) throws {
		let result: PhidgetReturnCode
		result = PhidgetLog_loges(Phidget_LogLevel(level.rawValue), source, message)
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
	}

	/**
	Manually rotate the log file. This will only have an effect if automatic rotation is disabled and the log file is larger than the specified maximum file size.

	- throws:
	An error or type `PhidgetError`
	*/
	public static func rotate() throws {
		let result: PhidgetReturnCode
		result = PhidgetLog_rotate()
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
	}

	/**
	Determines if the library is automatically rotating the log file

	- returns:
	If the library is automatically rotating the log file

	- throws:
	An error or type `PhidgetError`
	*/
	public static func isRotating() throws -> Bool {
		let result: PhidgetReturnCode
		var isrotating: Int32 = 0
		result = PhidgetLog_isRotating(&isrotating)
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
		return (isrotating == 0 ? false : true)
	}

	/**
	Gets the current log rotation parameters

	- returns:
		- size: The file size above which the log file should be rotated.
		- keepCount: The number of log files that will be kept after rotation.

	- throws:
	An error or type `PhidgetError`
	*/
	public static func getRotating() throws -> (size: UInt64, keepCount: Int) {
		let result: PhidgetReturnCode
		var size: UInt64 = 0
		var keepCount: Int32 = 0
		result = PhidgetLog_getRotating(&size, &keepCount)
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
		return (size: size, keepCount: Int(keepCount))
	}

	/**
	Sets log rotation parameters.

	- throws:
	An error or type `PhidgetError`

	- parameters:
		- size: The file size above which the file should be rotated in bytes. Min: 32768 (32 KiB) Def: 10485760 (10 MiB)
		- keepCount: The number of log files that should be kept after rotation. Min: 0 Def: 1 Max: 64
	*/
	public static func setRotating(size: UInt64, keepCount: Int) throws {
		let result: PhidgetReturnCode
		result = PhidgetLog_setRotating(size, Int32(keepCount))
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
	}

	/**
	Enables automatic rotation of the log file (the default).

	- throws:
	An error or type `PhidgetError`
	*/
	public static func enableRotating() throws {
		let result: PhidgetReturnCode
		result = PhidgetLog_enableRotating()
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
	}

	/**
	Disables automatic rotation of the log file.

	- throws:
	An error or type `PhidgetError`
	*/
	public static func disableRotating() throws {
		let result: PhidgetReturnCode
		result = PhidgetLog_disableRotating()
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
	}

	/**
	Adds a source to the Phidget logging system. This is useful for declaring a source and setting its log level before sending any messages.

	- throws:
	An error or type `PhidgetError`

	- parameters:
		- source: The source name
		- level: The log level of the source
	*/
	public static func addSource(source: String, level: LogLevel) throws {
		let result: PhidgetReturnCode
		result = PhidgetLog_addSource(source, Phidget_LogLevel(level.rawValue))
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
	}

	/**
	Gets the log level of the specified log source.

	- returns:
	The log level of the source

	- throws:
	An error or type `PhidgetError`

	- parameters:
		- source: The log source name
	*/
	public static func getSourceLevel(source: String) throws -> LogLevel {
		let result: PhidgetReturnCode
		var level: Phidget_LogLevel = PHIDGET_LOG_CRITICAL
		result = PhidgetLog_getSourceLevel(source, &level)
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
		return LogLevel(rawValue: level.rawValue)!
	}

	/**
	Sets the log level of the specified log source.

	- throws:
	An error or type `PhidgetError`

	- parameters:
		- source: The log source name
		- level: The new log level
	*/
	public static func setSourceLevel(source: String, level: LogLevel) throws {
		let result: PhidgetReturnCode
		result = PhidgetLog_setSourceLevel(source, Phidget_LogLevel(level.rawValue))
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
	}

}
