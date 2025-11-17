import Foundation
//import Phidget22

/**
The Digital Input class is used to monitor the state of Phidget digital inputs. Use digital inputs to monitor the state of buttons, switches, or switch-to-ground sensors.
*/
public class DigitalInputBase : Phidget {

	public init() {
		var h: PhidgetHandle?
		PhidgetDigitalInput_create(&h)
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
			PhidgetDigitalInput_delete(&chandle)
		}
	}

	/**
	The input polarity mode for your channel.

	*   See your device's User Guide for more information about what value to chooose for the `InputMode`

	- returns:
	The input mode value

	- throws:
	An error or type `PhidgetError`
	*/
	public func getInputMode() throws -> InputMode {
		let result: PhidgetReturnCode
		var inputMode: Phidget_InputMode = INPUT_MODE_NPN
		result = PhidgetDigitalInput_getInputMode(chandle, &inputMode)
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
		return InputMode(rawValue: inputMode.rawValue)!
	}

	/**
	The input polarity mode for your channel.

	*   See your device's User Guide for more information about what value to chooose for the `InputMode`

	- throws:
	An error or type `PhidgetError`

	- parameters:
		- inputMode: The input mode value
	*/
	public func setInputMode(_ inputMode: InputMode) throws {
		let result: PhidgetReturnCode
		result = PhidgetDigitalInput_setInputMode(chandle, Phidget_InputMode(inputMode.rawValue))
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
	}

	/**
	Choose the power supply voltage.

	*   Set this to the voltage specified in the attached sensor's data sheet to power it.
	*   Set to `PowerSupply.off` to turn off the supply to save power.

	- returns:
	The power supply value

	- throws:
	An error or type `PhidgetError`
	*/
	public func getPowerSupply() throws -> PowerSupply {
		let result: PhidgetReturnCode
		var powerSupply: Phidget_PowerSupply = POWER_SUPPLY_OFF
		result = PhidgetDigitalInput_getPowerSupply(chandle, &powerSupply)
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
		return PowerSupply(rawValue: powerSupply.rawValue)!
	}

	/**
	Choose the power supply voltage.

	*   Set this to the voltage specified in the attached sensor's data sheet to power it.
	*   Set to `PowerSupply.off` to turn off the supply to save power.

	- throws:
	An error or type `PhidgetError`

	- parameters:
		- powerSupply: The power supply value
	*/
	public func setPowerSupply(_ powerSupply: PowerSupply) throws {
		let result: PhidgetReturnCode
		result = PhidgetDigitalInput_setPowerSupply(chandle, Phidget_PowerSupply(powerSupply.rawValue))
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
	}

	/**
	The most recent state value that the channel has reported.

	- returns:
	The state value

	- throws:
	An error or type `PhidgetError`
	*/
	public func getState() throws -> Bool {
		let result: PhidgetReturnCode
		var state: Int32 = 0
		result = PhidgetDigitalInput_getState(chandle, &state)
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
		return (state == 0 ? false : true)
	}

	internal override func initializeEvents() {
		initializeBaseEvents()
		PhidgetDigitalInput_setOnStateChangeHandler(chandle, nativeStateChangeHandler, UnsafeMutableRawPointer(selfCtx!.toOpaque()))
	}

	internal override func uninitializeEvents() {
		uninitializeBaseEvents()
		PhidgetDigitalInput_setOnStateChangeHandler(chandle, nil, nil)
	}

	/**
	This event will occur when the state of the digital input has changed.

	*   The value will either be 0 or 1 (true or false).

	---
	## Parameters:
	*   `state`: The state value
	*/
	public let stateChange = Event<DigitalInput, Bool> ()
	let nativeStateChangeHandler : PhidgetDigitalInput_OnStateChangeCallback = { ch, ctx, state in
		let me = Unmanaged<DigitalInput>.fromOpaque(ctx!).takeUnretainedValue()
		me.stateChange.raise(me, (state == 0 ? false : true));
	}

}
