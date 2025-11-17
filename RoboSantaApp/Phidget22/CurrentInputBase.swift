import Foundation
//import Phidget22

/**
The Current Input class is used to measure current flowing through the Phidget from outside sources.

This class may be used on a simple current sensor, or sometimes on a more complex Phidget that measures the amount of current flowing through an attached device, such as a motor controller, for diagnostic or control purposes.
*/
public class CurrentInputBase : Phidget {

	public init() {
		var h: PhidgetHandle?
		PhidgetCurrentInput_create(&h)
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
			PhidgetCurrentInput_delete(&chandle)
		}
	}

	/**
	The most recent current value that the channel has reported.

	*   This value will always be between `MinCurrent` and `MaxCurrent`.

	- returns:
	The current value

	- throws:
	An error or type `PhidgetError`
	*/
	public func getCurrent() throws -> Double {
		let result: PhidgetReturnCode
		var current: Double = 0
		result = PhidgetCurrentInput_getCurrent(chandle, &current)
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
		return current
	}

	/**
	The minimum value the `CurrentChange` event will report.

	- returns:
	The current value

	- throws:
	An error or type `PhidgetError`
	*/
	public func getMinCurrent() throws -> Double {
		let result: PhidgetReturnCode
		var minCurrent: Double = 0
		result = PhidgetCurrentInput_getMinCurrent(chandle, &minCurrent)
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
		return minCurrent
	}

	/**
	The maximum value the `CurrentChange` event will report.

	- returns:
	The current value

	- throws:
	An error or type `PhidgetError`
	*/
	public func getMaxCurrent() throws -> Double {
		let result: PhidgetReturnCode
		var maxCurrent: Double = 0
		result = PhidgetCurrentInput_getMaxCurrent(chandle, &maxCurrent)
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
		return maxCurrent
	}

	/**
	The channel will not issue a `CurrentChange` event until the current value has changed by the amount specified by the `CurrentChangeTrigger`.

	*   Setting the `CurrentChangeTrigger` to 0 will result in the channel firing events every `DataInterval`. This is useful for applications that implement their own data filtering

	- returns:
	The change trigger value

	- throws:
	An error or type `PhidgetError`
	*/
	public func getCurrentChangeTrigger() throws -> Double {
		let result: PhidgetReturnCode
		var currentChangeTrigger: Double = 0
		result = PhidgetCurrentInput_getCurrentChangeTrigger(chandle, &currentChangeTrigger)
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
		return currentChangeTrigger
	}

	/**
	The channel will not issue a `CurrentChange` event until the current value has changed by the amount specified by the `CurrentChangeTrigger`.

	*   Setting the `CurrentChangeTrigger` to 0 will result in the channel firing events every `DataInterval`. This is useful for applications that implement their own data filtering

	- throws:
	An error or type `PhidgetError`

	- parameters:
		- currentChangeTrigger: The change trigger value
	*/
	public func setCurrentChangeTrigger(_ currentChangeTrigger: Double) throws {
		let result: PhidgetReturnCode
		result = PhidgetCurrentInput_setCurrentChangeTrigger(chandle, currentChangeTrigger)
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
	}

	/**
	The minimum value that `CurrentChangeTrigger` can be set to.

	- returns:
	The change trigger value

	- throws:
	An error or type `PhidgetError`
	*/
	public func getMinCurrentChangeTrigger() throws -> Double {
		let result: PhidgetReturnCode
		var minCurrentChangeTrigger: Double = 0
		result = PhidgetCurrentInput_getMinCurrentChangeTrigger(chandle, &minCurrentChangeTrigger)
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
		return minCurrentChangeTrigger
	}

	/**
	The maximum value that `CurrentChangeTrigger` can be set to.

	- returns:
	The change trigger value

	- throws:
	An error or type `PhidgetError`
	*/
	public func getMaxCurrentChangeTrigger() throws -> Double {
		let result: PhidgetReturnCode
		var maxCurrentChangeTrigger: Double = 0
		result = PhidgetCurrentInput_getMaxCurrentChangeTrigger(chandle, &maxCurrentChangeTrigger)
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
		return maxCurrentChangeTrigger
	}

	/**
	The `DataInterval` is the time that must elapse before the channel will fire another `CurrentChange` event.

	*   The data interval is bounded by `MinDataInterval` and `MaxDataInterval`.
	*   The timing between `CurrentChange` events can also be affected by the `CurrentChangeTrigger`.

	- returns:
	The data interval value

	- throws:
	An error or type `PhidgetError`
	*/
	public func getDataInterval() throws -> UInt32 {
		let result: PhidgetReturnCode
		var dataInterval: UInt32 = 0
		result = PhidgetCurrentInput_getDataInterval(chandle, &dataInterval)
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
		return dataInterval
	}

	/**
	The `DataInterval` is the time that must elapse before the channel will fire another `CurrentChange` event.

	*   The data interval is bounded by `MinDataInterval` and `MaxDataInterval`.
	*   The timing between `CurrentChange` events can also be affected by the `CurrentChangeTrigger`.

	- throws:
	An error or type `PhidgetError`

	- parameters:
		- dataInterval: The data interval value
	*/
	public func setDataInterval(_ dataInterval: UInt32) throws {
		let result: PhidgetReturnCode
		result = PhidgetCurrentInput_setDataInterval(chandle, dataInterval)
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
		result = PhidgetCurrentInput_getMinDataInterval(chandle, &minDataInterval)
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
		result = PhidgetCurrentInput_getMaxDataInterval(chandle, &maxDataInterval)
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
		result = PhidgetCurrentInput_getDataRate(chandle, &dataRate)
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
		result = PhidgetCurrentInput_setDataRate(chandle, dataRate)
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
		result = PhidgetCurrentInput_getMinDataRate(chandle, &minDataRate)
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
		result = PhidgetCurrentInput_getMaxDataRate(chandle, &maxDataRate)
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
		return maxDataRate
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
		result = PhidgetCurrentInput_getPowerSupply(chandle, &powerSupply)
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
		result = PhidgetCurrentInput_setPowerSupply(chandle, Phidget_PowerSupply(powerSupply.rawValue))
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
	}

	internal override func initializeEvents() {
		initializeBaseEvents()
		PhidgetCurrentInput_setOnCurrentChangeHandler(chandle, nativeCurrentChangeHandler, UnsafeMutableRawPointer(selfCtx!.toOpaque()))
	}

	internal override func uninitializeEvents() {
		uninitializeBaseEvents()
		PhidgetCurrentInput_setOnCurrentChangeHandler(chandle, nil, nil)
	}

	/**
	The most recent current value the channel has measured will be reported in this event, which occurs when the `DataInterval` has elapsed.

	*   If a `CurrentChangeTrigger` has been set to a non-zero value, the `CurrentChange` event will not occur until the current value has changed by at least the `CurrentChangeTrigger` value.

	---
	## Parameters:
	*   `current`: The current value
	*/
	public let currentChange = Event<CurrentInput, Double> ()
	let nativeCurrentChangeHandler : PhidgetCurrentInput_OnCurrentChangeCallback = { ch, ctx, current in
		let me = Unmanaged<CurrentInput>.fromOpaque(ctx!).takeUnretainedValue()
		me.currentChange.raise(me, current);
	}

}
