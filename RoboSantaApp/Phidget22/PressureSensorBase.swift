import Foundation
//import Phidget22

/**
The Pressure Sensor class gathers data from the pressure sensor on a Phidget board.

If you're using a simple 0-5V sensor that does not have its own firmware, use the VoltageInput or VoltageRatioInput class instead, as specified for your device.
*/
public class PressureSensorBase : Phidget {

	public init() {
		var h: PhidgetHandle?
		PhidgetPressureSensor_create(&h)
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
			PhidgetPressureSensor_delete(&chandle)
		}
	}

	/**
	The `DataInterval` is the time that must elapse before the channel will fire another `PressureChange` event.

	*   The data interval is bounded by `MinDataInterval` and `MaxDataInterval`.
	*   The timing between `PressureChange` events can also be affected by the `PressureChangeTrigger`.

	- returns:
	The data interval value

	- throws:
	An error or type `PhidgetError`
	*/
	public func getDataInterval() throws -> UInt32 {
		let result: PhidgetReturnCode
		var dataInterval: UInt32 = 0
		result = PhidgetPressureSensor_getDataInterval(chandle, &dataInterval)
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
		return dataInterval
	}

	/**
	The `DataInterval` is the time that must elapse before the channel will fire another `PressureChange` event.

	*   The data interval is bounded by `MinDataInterval` and `MaxDataInterval`.
	*   The timing between `PressureChange` events can also be affected by the `PressureChangeTrigger`.

	- throws:
	An error or type `PhidgetError`

	- parameters:
		- dataInterval: The data interval value
	*/
	public func setDataInterval(_ dataInterval: UInt32) throws {
		let result: PhidgetReturnCode
		result = PhidgetPressureSensor_setDataInterval(chandle, dataInterval)
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
		result = PhidgetPressureSensor_getMinDataInterval(chandle, &minDataInterval)
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
		result = PhidgetPressureSensor_getMaxDataInterval(chandle, &maxDataInterval)
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
		result = PhidgetPressureSensor_getDataRate(chandle, &dataRate)
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
		result = PhidgetPressureSensor_setDataRate(chandle, dataRate)
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
		result = PhidgetPressureSensor_getMinDataRate(chandle, &minDataRate)
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
		result = PhidgetPressureSensor_getMaxDataRate(chandle, &maxDataRate)
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
		return maxDataRate
	}

	/**
	The most recent pressure value that the channel has reported.

	*   This value will always be between `MinPressure` and `MaxPressure`.

	- returns:
	The pressure value

	- throws:
	An error or type `PhidgetError`
	*/
	public func getPressure() throws -> Double {
		let result: PhidgetReturnCode
		var pressure: Double = 0
		result = PhidgetPressureSensor_getPressure(chandle, &pressure)
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
		return pressure
	}

	/**
	The minimum value the `PressureChange` event will report.

	- returns:
	The pressure value

	- throws:
	An error or type `PhidgetError`
	*/
	public func getMinPressure() throws -> Double {
		let result: PhidgetReturnCode
		var minPressure: Double = 0
		result = PhidgetPressureSensor_getMinPressure(chandle, &minPressure)
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
		return minPressure
	}

	/**
	The maximum value the `PressureChange` event will report.

	- returns:
	The pressure value

	- throws:
	An error or type `PhidgetError`
	*/
	public func getMaxPressure() throws -> Double {
		let result: PhidgetReturnCode
		var maxPressure: Double = 0
		result = PhidgetPressureSensor_getMaxPressure(chandle, &maxPressure)
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
		return maxPressure
	}

	/**
	The channel will not issue a `PressureChange` event until the pressure value has changed by the amount specified by the `PressureChangeTrigger`.

	*   Setting the `PressureChangeTrigger` to 0 will result in the channel firing events every `DataInterval`. This is useful for applications that implement their own data filtering

	- returns:
	The change trigger value

	- throws:
	An error or type `PhidgetError`
	*/
	public func getPressureChangeTrigger() throws -> Double {
		let result: PhidgetReturnCode
		var pressureChangeTrigger: Double = 0
		result = PhidgetPressureSensor_getPressureChangeTrigger(chandle, &pressureChangeTrigger)
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
		return pressureChangeTrigger
	}

	/**
	The channel will not issue a `PressureChange` event until the pressure value has changed by the amount specified by the `PressureChangeTrigger`.

	*   Setting the `PressureChangeTrigger` to 0 will result in the channel firing events every `DataInterval`. This is useful for applications that implement their own data filtering

	- throws:
	An error or type `PhidgetError`

	- parameters:
		- pressureChangeTrigger: The change trigger value
	*/
	public func setPressureChangeTrigger(_ pressureChangeTrigger: Double) throws {
		let result: PhidgetReturnCode
		result = PhidgetPressureSensor_setPressureChangeTrigger(chandle, pressureChangeTrigger)
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
	}

	/**
	The minimum value that `PressureChangeTrigger` can be set to.

	- returns:
	The change trigger value

	- throws:
	An error or type `PhidgetError`
	*/
	public func getMinPressureChangeTrigger() throws -> Double {
		let result: PhidgetReturnCode
		var minPressureChangeTrigger: Double = 0
		result = PhidgetPressureSensor_getMinPressureChangeTrigger(chandle, &minPressureChangeTrigger)
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
		return minPressureChangeTrigger
	}

	/**
	The maximum value that `PressureChangeTrigger` can be set to.

	- returns:
	The change trigger value

	- throws:
	An error or type `PhidgetError`
	*/
	public func getMaxPressureChangeTrigger() throws -> Double {
		let result: PhidgetReturnCode
		var maxPressureChangeTrigger: Double = 0
		result = PhidgetPressureSensor_getMaxPressureChangeTrigger(chandle, &maxPressureChangeTrigger)
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
		return maxPressureChangeTrigger
	}

	internal override func initializeEvents() {
		initializeBaseEvents()
		PhidgetPressureSensor_setOnPressureChangeHandler(chandle, nativePressureChangeHandler, UnsafeMutableRawPointer(selfCtx!.toOpaque()))
	}

	internal override func uninitializeEvents() {
		uninitializeBaseEvents()
		PhidgetPressureSensor_setOnPressureChangeHandler(chandle, nil, nil)
	}

	/**
	The most recent pressure value the channel has measured will be reported in this event, which occurs when the `DataInterval` has elapsed.

	*   If a `PressureChangeTrigger` has been set to a non-zero value, the `PressureChange` event will not occur until the pressure has changed by at least the `PressureChangeTrigger` value.

	---
	## Parameters:
	*   `pressure`: The new measured pressure
	*/
	public let pressureChange = Event<PressureSensor, Double> ()
	let nativePressureChangeHandler : PhidgetPressureSensor_OnPressureChangeCallback = { ch, ctx, pressure in
		let me = Unmanaged<PressureSensor>.fromOpaque(ctx!).takeUnretainedValue()
		me.pressureChange.raise(me, pressure);
	}

}
