import Foundation
//import Phidget22

/**
Dictionaries are useful for passing information between multiple programs using Phidgets. A common example would be to have one program controlling your application that receives commands sent via a Phidget dictionary from a web interface, as outlined in many of our [articles](/?view=articles).

Keys can be thought of as being similar to variable names, with their values as their associated value. Phidget dictionaries contain groups of related key-value pairs, and are stored on a central [Phigdet Network Server](/docs/Phidget_Network_Server). Dictionaries, and the key-value pairs within may be accessed from programs that have access to the [Phigdet Network Server](/docs/Phidget_Network_Server).

The Dictionary API supports connecting to a dictionary on the server, managing key-value pairs, and monitoring changes made to the dictionary.

More information on Phidget Dictionaries can be found on the [Phidget Dictionary](/docs/Phidget_Dictionary) support page.
*/
public class DictionaryBase : Phidget {

	public init() {
		var h: PhidgetHandle?
		PhidgetDictionary_create(&h)
		super.init(h!)
		initializeEvents()
	}

	internal override init(_ handle: PhidgetHandle) {
		super.init(handle)
	}

    @MainActor deinit {
		if (retained) {
			Phidget_release(&chandle)
		} else {
			uninitializeEvents()
			PhidgetDictionary_delete(&chandle)
		}
	}

	/**
	Adds a new key value pair to the dictionary. It is an error if the key already exits.

	- throws:
	An error or type `PhidgetError`

	- parameters:
		- key: The key to add
		- value: The value to add
	*/
	public func add(key: String, value: String) throws {
		let result: PhidgetReturnCode
		result = PhidgetDictionary_add(chandle, key, value)
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
	}

	/**
	Removes every key from the dictionary

	- throws:
	An error or type `PhidgetError`
	*/
	public func removeAll() throws {
		let result: PhidgetReturnCode
		result = PhidgetDictionary_removeAll(chandle)
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
	}

	/**
	Removes the key from the dictionary

	- throws:
	An error or type `PhidgetError`

	- parameters:
		- key: The key to remove
	*/
	public func remove(key: String) throws {
		let result: PhidgetReturnCode
		result = PhidgetDictionary_remove(chandle, key)
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
	}

	/**
	Sets the value of a key, or creates the key value pair if the key does not already exist.

	- throws:
	An error or type `PhidgetError`

	- parameters:
		- key: The key to set
		- value: The value to set
	*/
	public func set(key: String, value: String) throws {
		let result: PhidgetReturnCode
		result = PhidgetDictionary_set(chandle, key, value)
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
	}

	/**
	Updates a key value pair in the dictionary. It is an error if the key does not exist.

	- throws:
	An error or type `PhidgetError`

	- parameters:
		- key: The key to update
		- value: The value to set
	*/
	public func update(key: String, value: String) throws {
		let result: PhidgetReturnCode
		result = PhidgetDictionary_update(chandle, key, value)
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
	}

	internal override func initializeEvents() {
		initializeBaseEvents()
		PhidgetDictionary_setOnAddHandler(chandle, nativeAddHandler, UnsafeMutableRawPointer(selfCtx!.toOpaque()))
		PhidgetDictionary_setOnRemoveHandler(chandle, nativeRemoveHandler, UnsafeMutableRawPointer(selfCtx!.toOpaque()))
		PhidgetDictionary_setOnUpdateHandler(chandle, nativeUpdateHandler, UnsafeMutableRawPointer(selfCtx!.toOpaque()))
	}

	internal override func uninitializeEvents() {
		uninitializeBaseEvents()
		PhidgetDictionary_setOnAddHandler(chandle, nil, nil)
		PhidgetDictionary_setOnRemoveHandler(chandle, nil, nil)
		PhidgetDictionary_setOnUpdateHandler(chandle, nil, nil)
	}

	/**
	Occurs when a new key value pair is added to the dictionary.

	---
	## Parameters:
	*   `key`: The key that was added
	*   `value`: The value of the new key
	*/
	public let add = Event<Dictionary, (key: String, value: String)> ()
	let nativeAddHandler : PhidgetDictionary_OnAddCallback = { ch, ctx, key, value in
		let me = Unmanaged<Dictionary>.fromOpaque(ctx!).takeUnretainedValue()
		me.add.raise(me, (String(cString: key!), String(cString: value!)));
	}

	/**
	Occurs when a key is removed from the dictionary.

	---
	## Parameters:
	*   `key`: The key that was removed
	*/
	public let remove = Event<Dictionary, String> ()
	let nativeRemoveHandler : PhidgetDictionary_OnRemoveCallback = { ch, ctx, key in
		let me = Unmanaged<Dictionary>.fromOpaque(ctx!).takeUnretainedValue()
		me.remove.raise(me, String(cString: key!));
	}

	/**
	Occurs when a change is made to a key value pair in the dictionary.

	---
	## Parameters:
	*   `key`: The key whose value was updated
	*   `value`: The new value
	*/
	public let update = Event<Dictionary, (key: String, value: String)> ()
	let nativeUpdateHandler : PhidgetDictionary_OnUpdateCallback = { ch, ctx, key, value in
		let me = Unmanaged<Dictionary>.fromOpaque(ctx!).takeUnretainedValue()
		me.update.raise(me, (String(cString: key!), String(cString: value!)));
	}

}
