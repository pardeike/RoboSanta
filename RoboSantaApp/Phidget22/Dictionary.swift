import Foundation
//import Phidget22

/**
Dictionaries are useful for passing information between multiple programs using Phidgets. A common example would be to have one program controlling your application that receives commands sent via a Phidget dictionary from a web interface, as outlined in many of our [articles](/?view=articles).

Keys can be thought of as being similar to variable names, with their values as their associated value. Phidget dictionaries contain groups of related key-value pairs, and are stored on a central [Phigdet Network Server](/docs/Phidget_Network_Server). Dictionaries, and the key-value pairs within may be accessed from programs that have access to the [Phigdet Network Server](/docs/Phidget_Network_Server).

The Dictionary API supports connecting to a dictionary on the server, managing key-value pairs, and monitoring changes made to the dictionary.

More information on Phidget Dictionaries can be found on the [Phidget Dictionary](/docs/Phidget_Dictionary) support page.
*/
public class Dictionary: DictionaryBase {

	/**
	Gets the value associated with the given key from the dictionary

	- returns:
	The value, or nil if the key doesn't exist
	
	- throws:
	An error or type `PhidgetError`
	
	- parameters:
		- key: The key whose value is desired
	*/
	public func get(key: String) throws -> String? {
		let result: PhidgetReturnCode
		let valueString: UnsafeMutablePointer<CChar> = UnsafeMutablePointer<CChar>.allocate(capacity: 65536)
		let valueStringLen: Int = 65536
		result = PhidgetDictionary_get(chandle, key, valueString, valueStringLen)
		if result == EPHIDGET_NOENT {
			valueString.deallocate()
			return nil
		}
		if result != EPHIDGET_OK {
			valueString.deallocate()
			throw (PhidgetError(code: result))
		}
		let str = String(cString: valueString)
		valueString.deallocate()
		return str
	}
	
	/**
	Scans the keys in the dictionary, indexed by `start` of the first key in the dictionary if `start` is `nil` or an empty string
	
	- returns:
	The list of keys
	
	- throws:
	An error or type `PhidgetError`
	
	- parameters:
		- start: The key to start the scan from
	*/
	public func scan(start: String? = nil) throws -> [Substring] {
		let result: PhidgetReturnCode
		let keysString: UnsafeMutablePointer<CChar> = UnsafeMutablePointer<CChar>.allocate(capacity: 65536)
		let keysStringLen: Int = 65536
		result = PhidgetDictionary_scan(chandle, start, keysString, keysStringLen)
		if result != EPHIDGET_OK {
			keysString.deallocate()
			throw (PhidgetError(code: result))
		}
		let keys = String(cString: keysString)
		keysString.deallocate()
		return keys.split(separator: "\n")
	}
}
