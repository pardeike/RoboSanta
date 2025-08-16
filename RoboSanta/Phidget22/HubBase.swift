import Foundation
//import Phidget22

/**
The hub class allows you to control power to VINT hub ports.
*/
public class HubBase : Phidget {

	public init() {
		var h: PhidgetHandle?
		PhidgetHub_create(&h)
		super.init(h!)
		initializeEvents()
	}

	internal override init(_ handle: PhidgetHandle) {
		super.init(handle)
	}

	deinit {
		if (retained) {
			Phidget_release(&chandle)
		} else {
			uninitializeEvents()
			PhidgetHub_delete(&chandle)
		}
	}

	/**
	Enables / disables Auto Set Speed on the hub port. When enabled, and a supported VINT device is attached, the **HubPortSpeed** will automatically be set to the fastest reliable speed. This is enabled by default on supported VINT Hubs.

	- throws:
	An error or type `PhidgetError`

	- parameters:
		- port: The Hub port
		- state: The AutoSetSpeed state
	*/
	public func setPortAutoSetSpeed(port: Int, state: Bool) throws {
		let result: PhidgetReturnCode
		result = PhidgetHub_setPortAutoSetSpeed(chandle, Int32(port), (state ? 1 : 0))
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
	}

	/**
	The max communication speed of a high-speed capable VINT Port.

	- returns:
	The max speed

	- throws:
	An error or type `PhidgetError`

	- parameters:
		- port: The Hub port
	*/
	public func getPortMaxSpeed(port: Int) throws -> UInt32 {
		let result: PhidgetReturnCode
		var state: UInt32 = 0
		result = PhidgetHub_getPortMaxSpeed(chandle, Int32(port), &state)
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
		return state
	}

	/**
	Gets the mode of the selected hub port. VINT devices will not show up when the port is in digital/analog mode.

	- returns:
	The mode the port is in

	- throws:
	An error or type `PhidgetError`

	- parameters:
		- port: The port being read
	*/
	public func getPortMode(port: Int) throws -> HubPortMode {
		let result: PhidgetReturnCode
		var mode: PhidgetHub_PortMode = PORT_MODE_VINT_PORT
		result = PhidgetHub_getPortMode(chandle, Int32(port), &mode)
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
		return HubPortMode(rawValue: mode.rawValue)!
	}

	/**
	Sets the mode of the selected port. This could be used to set a port back to VINT mode if it was left in digital/analog mode.

	- throws:
	An error or type `PhidgetError`

	- parameters:
		- port: The port being set
		- mode: The mode the port is being set to
	*/
	public func setPortMode(port: Int, mode: HubPortMode) throws {
		let result: PhidgetReturnCode
		result = PhidgetHub_setPortMode(chandle, Int32(port), PhidgetHub_PortMode(mode.rawValue))
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
	}

	/**
	Gets the VINT Hub Port power state

	- returns:
	The power state

	- throws:
	An error or type `PhidgetError`

	- parameters:
		- port: The Hub port
	*/
	public func getPortPower(port: Int) throws -> Bool {
		let result: PhidgetReturnCode
		var state: Int32 = 0
		result = PhidgetHub_getPortPower(chandle, Int32(port), &state)
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
		return (state == 0 ? false : true)
	}

	/**
	Controls power to the VINT Hub Port.

	- throws:
	An error or type `PhidgetError`

	- parameters:
		- port: The Hub port
		- state: The power state
	*/
	public func setPortPower(port: Int, state: Bool) throws {
		let result: PhidgetReturnCode
		result = PhidgetHub_setPortPower(chandle, Int32(port), (state ? 1 : 0))
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
	}

	/**
	Indicates that this VINT Port support Auto Set Speed.

	- returns:
	The supported state

	- throws:
	An error or type `PhidgetError`

	- parameters:
		- port: The Hub port
	*/
	public func getPortSupportsAutoSetSpeed(port: Int) throws -> Bool {
		let result: PhidgetReturnCode
		var state: Int32 = 0
		result = PhidgetHub_getPortSupportsAutoSetSpeed(chandle, Int32(port), &state)
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
		return (state == 0 ? false : true)
	}

	/**
	Indicates that the communication speed of this VINT port can be set.

	- returns:
	The supported state

	- throws:
	An error or type `PhidgetError`

	- parameters:
		- port: The Hub port
	*/
	public func getPortSupportsSetSpeed(port: Int) throws -> Bool {
		let result: PhidgetReturnCode
		var state: Int32 = 0
		result = PhidgetHub_getPortSupportsSetSpeed(chandle, Int32(port), &state)
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
		return (state == 0 ? false : true)
	}

}
