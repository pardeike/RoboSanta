import Foundation
//import Phidget22

/**
The Light Sensor class gathers data from the light sensor on a Phidget board.

If you're using a simple 0-5V sensor that does not have its own firmware, use the VoltageInput or VoltageRatioInput class instead, as specified for your device.
*/
public class LightSensorBase : Phidget {

	public init() {
		var h: PhidgetHandle?
		PhidgetLightSensor_create(&h)
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
			PhidgetLightSensor_delete(&chandle)
		}
	}

	/**
	The `DataInterval` is the time that must elapse before the channel will fire another `IlluminanceChange` event.

	*   The data interval is bounded by `MinDataInterval` and `MaxDataInterval`.
	*   The timing between `IlluminanceChange` events can also be affected by the `IlluminanceChangeTrigger`.

	- returns:
	The data interval value

	- throws:
	An error or type `PhidgetError`
	*/
	public func getDataInterval() throws -> UInt32 {
		let result: PhidgetReturnCode
		var dataInterval: UInt32 = 0
		result = PhidgetLightSensor_getDataInterval(chandle, &dataInterval)
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
		return dataInterval
	}

	/**
	The `DataInterval` is the time that must elapse before the channel will fire another `IlluminanceChange` event.

	*   The data interval is bounded by `MinDataInterval` and `MaxDataInterval`.
	*   The timing between `IlluminanceChange` events can also be affected by the `IlluminanceChangeTrigger`.

	- throws:
	An error or type `PhidgetError`

	- parameters:
		- dataInterval: The data interval value
	*/
	public func setDataInterval(_ dataInterval: UInt32) throws {
		let result: PhidgetReturnCode
		result = PhidgetLightSensor_setDataInterval(chandle, dataInterval)
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
		result = PhidgetLightSensor_getMinDataInterval(chandle, &minDataInterval)
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
		result = PhidgetLightSensor_getMaxDataInterval(chandle, &maxDataInterval)
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
		result = PhidgetLightSensor_getDataRate(chandle, &dataRate)
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
		result = PhidgetLightSensor_setDataRate(chandle, dataRate)
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
		result = PhidgetLightSensor_getMinDataRate(chandle, &minDataRate)
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
		result = PhidgetLightSensor_getMaxDataRate(chandle, &maxDataRate)
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
		return maxDataRate
	}

	/**
	The most recent illuminance value that the channel has reported.

	*   This value will always be between `MinIlluminance` and `MaxIlluminance`.

	- returns:
	The illuminance value

	- throws:
	An error or type `PhidgetError`
	*/
	public func getIlluminance() throws -> Double {
		let result: PhidgetReturnCode
		var illuminance: Double = 0
		result = PhidgetLightSensor_getIlluminance(chandle, &illuminance)
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
		return illuminance
	}

	/**
	The minimum value the `IlluminanceChange` event will report.

	- returns:
	The illuminance value

	- throws:
	An error or type `PhidgetError`
	*/
	public func getMinIlluminance() throws -> Double {
		let result: PhidgetReturnCode
		var minIlluminance: Double = 0
		result = PhidgetLightSensor_getMinIlluminance(chandle, &minIlluminance)
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
		return minIlluminance
	}

	/**
	The maximum value the `IlluminanceChange` event will report.

	- returns:
	The illuminance value

	- throws:
	An error or type `PhidgetError`
	*/
	public func getMaxIlluminance() throws -> Double {
		let result: PhidgetReturnCode
		var maxIlluminance: Double = 0
		result = PhidgetLightSensor_getMaxIlluminance(chandle, &maxIlluminance)
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
		return maxIlluminance
	}

	/**
	The channel will not issue a `IlluminanceChange` event until the illuminance value has changed by the amount specified by the `IlluminanceChangeTrigger`.

	*   Setting the `IlluminanceChangeTrigger` to 0 will result in the channel firing events every `DataInterval`. This is useful for applications that implement their own data filtering

	- returns:
	The change trigger value

	- throws:
	An error or type `PhidgetError`
	*/
	public func getIlluminanceChangeTrigger() throws -> Double {
		let result: PhidgetReturnCode
		var illuminanceChangeTrigger: Double = 0
		result = PhidgetLightSensor_getIlluminanceChangeTrigger(chandle, &illuminanceChangeTrigger)
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
		return illuminanceChangeTrigger
	}

	/**
	The channel will not issue a `IlluminanceChange` event until the illuminance value has changed by the amount specified by the `IlluminanceChangeTrigger`.

	*   Setting the `IlluminanceChangeTrigger` to 0 will result in the channel firing events every `DataInterval`. This is useful for applications that implement their own data filtering

	- throws:
	An error or type `PhidgetError`

	- parameters:
		- illuminanceChangeTrigger: The change trigger value
	*/
	public func setIlluminanceChangeTrigger(_ illuminanceChangeTrigger: Double) throws {
		let result: PhidgetReturnCode
		result = PhidgetLightSensor_setIlluminanceChangeTrigger(chandle, illuminanceChangeTrigger)
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
	}

	/**
	The minimum value that `IlluminanceChangeTrigger` can be set to.

	- returns:
	The change trigger value

	- throws:
	An error or type `PhidgetError`
	*/
	public func getMinIlluminanceChangeTrigger() throws -> Double {
		let result: PhidgetReturnCode
		var minIlluminanceChangeTrigger: Double = 0
		result = PhidgetLightSensor_getMinIlluminanceChangeTrigger(chandle, &minIlluminanceChangeTrigger)
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
		return minIlluminanceChangeTrigger
	}

	/**
	The maximum value that `IlluminanceChangeTrigger` can be set to.

	- returns:
	The change trigger value

	- throws:
	An error or type `PhidgetError`
	*/
	public func getMaxIlluminanceChangeTrigger() throws -> Double {
		let result: PhidgetReturnCode
		var maxIlluminanceChangeTrigger: Double = 0
		result = PhidgetLightSensor_getMaxIlluminanceChangeTrigger(chandle, &maxIlluminanceChangeTrigger)
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
		return maxIlluminanceChangeTrigger
	}

	internal override func initializeEvents() {
		initializeBaseEvents()
		PhidgetLightSensor_setOnIlluminanceChangeHandler(chandle, nativeIlluminanceChangeHandler, UnsafeMutableRawPointer(selfCtx!.toOpaque()))
	}

	internal override func uninitializeEvents() {
		uninitializeBaseEvents()
		PhidgetLightSensor_setOnIlluminanceChangeHandler(chandle, nil, nil)
	}

	/**
	The most recent illuminance value the channel has measured will be reported in this event, which occurs when the `DataInterval` has elapsed.

	*   If a `IlluminanceChangeTrigger` has been set to a non-zero value, the `IlluminanceChange` event will not occur until the illuminance has changed by at least the `IlluminanceChangeTrigger` value.

	---
	## Parameters:
	*   `illuminance`: The current illuminance
	*/
	public let illuminanceChange = Event<LightSensor, Double> ()
	let nativeIlluminanceChangeHandler : PhidgetLightSensor_OnIlluminanceChangeCallback = { ch, ctx, illuminance in
		let me = Unmanaged<LightSensor>.fromOpaque(ctx!).takeUnretainedValue()
		me.illuminanceChange.raise(me, illuminance);
	}

}
