import Foundation
//import Phidget22

/**
The Resistance Input class measures the resistance of a circuit connected to the Phidget, which is used to read resistance-based sensors such as platinum RTDs.
*/
public class ResistanceInputBase : Phidget {

	public init() {
		var h: PhidgetHandle?
		PhidgetResistanceInput_create(&h)
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
			PhidgetResistanceInput_delete(&chandle)
		}
	}

	/**
	The `DataInterval` is the time that must elapse before the channel will fire another `ResistanceChange` event.

	*   The data interval is bounded by `MinDataInterval` and `MaxDataInterval`.
	*   The timing between `ResistanceChange` events can also be affected by the `ResistanceChangeTrigger`.

	- returns:
	The data interval value

	- throws:
	An error or type `PhidgetError`
	*/
	public func getDataInterval() throws -> UInt32 {
		let result: PhidgetReturnCode
		var dataInterval: UInt32 = 0
		result = PhidgetResistanceInput_getDataInterval(chandle, &dataInterval)
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
		return dataInterval
	}

	/**
	The `DataInterval` is the time that must elapse before the channel will fire another `ResistanceChange` event.

	*   The data interval is bounded by `MinDataInterval` and `MaxDataInterval`.
	*   The timing between `ResistanceChange` events can also be affected by the `ResistanceChangeTrigger`.

	- throws:
	An error or type `PhidgetError`

	- parameters:
		- dataInterval: The data interval value
	*/
	public func setDataInterval(_ dataInterval: UInt32) throws {
		let result: PhidgetReturnCode
		result = PhidgetResistanceInput_setDataInterval(chandle, dataInterval)
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
	}

	/**
	The minimum value that `DataInterval` can be set to.

	- returns:
	The data interval value

	- throws:
	An error or type `PhidgetError`
	*/
	public func getMinDataInterval() throws -> UInt32 {
		let result: PhidgetReturnCode
		var minDataInterval: UInt32 = 0
		result = PhidgetResistanceInput_getMinDataInterval(chandle, &minDataInterval)
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
		return minDataInterval
	}

	/**
	The maximum value that `DataInterval` can be set to.

	- returns:
	The data interval value

	- throws:
	An error or type `PhidgetError`
	*/
	public func getMaxDataInterval() throws -> UInt32 {
		let result: PhidgetReturnCode
		var maxDataInterval: UInt32 = 0
		result = PhidgetResistanceInput_getMaxDataInterval(chandle, &maxDataInterval)
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
		return maxDataInterval
	}

	/**
	The `DataRate` is the frequency of events from the device.

	*   The data rate is bounded by `MinDataRate` and `MaxDataRate`.
	*   Changing `DataRate` will change the channel's `DataInterval` to a corresponding value, rounded to the nearest integer number of milliseconds.
	*   The timing between events can also affected by the change trigger.

	- returns:
	The data rate for the channel

	- throws:
	An error or type `PhidgetError`
	*/
	public func getDataRate() throws -> Double {
		let result: PhidgetReturnCode
		var dataRate: Double = 0
		result = PhidgetResistanceInput_getDataRate(chandle, &dataRate)
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
		return dataRate
	}

	/**
	The `DataRate` is the frequency of events from the device.

	*   The data rate is bounded by `MinDataRate` and `MaxDataRate`.
	*   Changing `DataRate` will change the channel's `DataInterval` to a corresponding value, rounded to the nearest integer number of milliseconds.
	*   The timing between events can also affected by the change trigger.

	- throws:
	An error or type `PhidgetError`

	- parameters:
		- dataRate: The data rate for the channel
	*/
	public func setDataRate(_ dataRate: Double) throws {
		let result: PhidgetReturnCode
		result = PhidgetResistanceInput_setDataRate(chandle, dataRate)
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
	}

	/**
	The minimum value that `DataRate` can be set to.

	- returns:
	The data rate value

	- throws:
	An error or type `PhidgetError`
	*/
	public func getMinDataRate() throws -> Double {
		let result: PhidgetReturnCode
		var minDataRate: Double = 0
		result = PhidgetResistanceInput_getMinDataRate(chandle, &minDataRate)
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
		return minDataRate
	}

	/**
	The maximum value that `DataRate` can be set to.

	- returns:
	The data rate value

	- throws:
	An error or type `PhidgetError`
	*/
	public func getMaxDataRate() throws -> Double {
		let result: PhidgetReturnCode
		var maxDataRate: Double = 0
		result = PhidgetResistanceInput_getMaxDataRate(chandle, &maxDataRate)
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
		return maxDataRate
	}

	/**
	The most recent resistance value that the channel has reported.

	*   This value will always be between `MinResistance` and `MaxResistance`.
	*   The `Resistance` value will change when the device is also being used as a temperature sensor. This is a side effect of increasing accuracy on the temperature channel.

	- returns:
	The resistance value

	- throws:
	An error or type `PhidgetError`
	*/
	public func getResistance() throws -> Double {
		let result: PhidgetReturnCode
		var resistance: Double = 0
		result = PhidgetResistanceInput_getResistance(chandle, &resistance)
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
		return resistance
	}

	/**
	The minimum value the `ResistanceChange` event will report.

	*   When the device is also being used as a TemperatureSensor the `MinResistance` and `MaxResistance` will not represent the true input range. This is a side effect of increasing accuracy on the temperature channel.

	- returns:
	The minimum resistance

	- throws:
	An error or type `PhidgetError`
	*/
	public func getMinResistance() throws -> Double {
		let result: PhidgetReturnCode
		var minResistance: Double = 0
		result = PhidgetResistanceInput_getMinResistance(chandle, &minResistance)
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
		return minResistance
	}

	/**
	The maximum value the `ResistanceChange` event will report.

	- returns:
	The resistance value

	- throws:
	An error or type `PhidgetError`
	*/
	public func getMaxResistance() throws -> Double {
		let result: PhidgetReturnCode
		var maxResistance: Double = 0
		result = PhidgetResistanceInput_getMaxResistance(chandle, &maxResistance)
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
		return maxResistance
	}

	/**
	The channel will not issue a `ResistanceChange` event until the resistance value has changed by the amount specified by the `ResistanceChangeTrigger`.

	*   Setting the `ResistanceChangeTrigger` to 0 will result in the channel firing events every `DataInterval`. This is useful for applications that implement their own data filtering

	- returns:
	The change trigger value

	- throws:
	An error or type `PhidgetError`
	*/
	public func getResistanceChangeTrigger() throws -> Double {
		let result: PhidgetReturnCode
		var resistanceChangeTrigger: Double = 0
		result = PhidgetResistanceInput_getResistanceChangeTrigger(chandle, &resistanceChangeTrigger)
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
		return resistanceChangeTrigger
	}

	/**
	The channel will not issue a `ResistanceChange` event until the resistance value has changed by the amount specified by the `ResistanceChangeTrigger`.

	*   Setting the `ResistanceChangeTrigger` to 0 will result in the channel firing events every `DataInterval`. This is useful for applications that implement their own data filtering

	- throws:
	An error or type `PhidgetError`

	- parameters:
		- resistanceChangeTrigger: The change trigger value
	*/
	public func setResistanceChangeTrigger(_ resistanceChangeTrigger: Double) throws {
		let result: PhidgetReturnCode
		result = PhidgetResistanceInput_setResistanceChangeTrigger(chandle, resistanceChangeTrigger)
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
	}

	/**
	The minimum value that the `ResistanceChangeTrigger` can be set to.

	- returns:
	The change trigger value

	- throws:
	An error or type `PhidgetError`
	*/
	public func getMinResistanceChangeTrigger() throws -> Double {
		let result: PhidgetReturnCode
		var minResistanceChangeTrigger: Double = 0
		result = PhidgetResistanceInput_getMinResistanceChangeTrigger(chandle, &minResistanceChangeTrigger)
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
		return minResistanceChangeTrigger
	}

	/**
	The maximum value that `ResistanceChangeTrigger` can be set to.

	- returns:
	The change trigger value

	- throws:
	An error or type `PhidgetError`
	*/
	public func getMaxResistanceChangeTrigger() throws -> Double {
		let result: PhidgetReturnCode
		var maxResistanceChangeTrigger: Double = 0
		result = PhidgetResistanceInput_getMaxResistanceChangeTrigger(chandle, &maxResistanceChangeTrigger)
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
		return maxResistanceChangeTrigger
	}

	/**
	Select the RTD wiring configuration.

	*   More information about RTD wiring can be found in the user guide.

	- returns:
	Wire setup value

	- throws:
	An error or type `PhidgetError`
	*/
	public func getRTDWireSetup() throws -> RTDWireSetup {
		let result: PhidgetReturnCode
		var rTDWireSetup: Phidget_RTDWireSetup = RTD_WIRE_SETUP_2WIRE
		result = PhidgetResistanceInput_getRTDWireSetup(chandle, &rTDWireSetup)
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
		return RTDWireSetup(rawValue: rTDWireSetup.rawValue)!
	}

	/**
	Select the RTD wiring configuration.

	*   More information about RTD wiring can be found in the user guide.

	- throws:
	An error or type `PhidgetError`

	- parameters:
		- RTDWireSetup: Wire setup value
	*/
	public func setRTDWireSetup(_ RTDWireSetup: RTDWireSetup) throws {
		let result: PhidgetReturnCode
		result = PhidgetResistanceInput_setRTDWireSetup(chandle, Phidget_RTDWireSetup(RTDWireSetup.rawValue))
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
	}

	internal override func initializeEvents() {
		initializeBaseEvents()
		PhidgetResistanceInput_setOnResistanceChangeHandler(chandle, nativeResistanceChangeHandler, UnsafeMutableRawPointer(selfCtx!.toOpaque()))
	}

	internal override func uninitializeEvents() {
		uninitializeBaseEvents()
		PhidgetResistanceInput_setOnResistanceChangeHandler(chandle, nil, nil)
	}

	/**
	The most recent resistance value the channel has measured will be reported in this event, which occurs when the `DataInterval` has elapsed.

	*   If a `ResistanceChangeTrigger` has been set to a non-zero value, the `ResistanceChange` event will not occur until the resistance has changed by at least the `ResistanceChangeTrigger` value.

	---
	## Parameters:
	*   `resistance`: The resistance value
	*/
	public let resistanceChange = Event<ResistanceInput, Double> ()
	let nativeResistanceChangeHandler : PhidgetResistanceInput_OnResistanceChangeCallback = { ch, ctx, resistance in
		let me = Unmanaged<ResistanceInput>.fromOpaque(ctx!).takeUnretainedValue()
		me.resistanceChange.raise(me, resistance);
	}

}
