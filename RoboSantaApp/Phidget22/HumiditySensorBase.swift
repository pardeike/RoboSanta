import Foundation
//import Phidget22

/**
The Humidity Sensor class gathers relative humidity data from the Phidget and makes it available to your code.

If you're using a simple 0-5V sensor that does not have its own firmware, use the VoltageInput or VoltageRatioInput class instead, as specified for your device.
*/
public class HumiditySensorBase : Phidget {

	public init() {
		var h: PhidgetHandle?
		PhidgetHumiditySensor_create(&h)
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
			PhidgetHumiditySensor_delete(&chandle)
		}
	}

	/**
	The `DataInterval` is the time that must elapse before the channel will fire another `HumidityChange` event.

	*   The data interval is bounded by `MinDataInterval` and `MaxDataInterval`.
	*   The timing between `HumidityChange` events can also be affected by the `HumidityChangeTrigger`.

	- returns:
	The data interval value

	- throws:
	An error or type `PhidgetError`
	*/
	public func getDataInterval() throws -> UInt32 {
		let result: PhidgetReturnCode
		var dataInterval: UInt32 = 0
		result = PhidgetHumiditySensor_getDataInterval(chandle, &dataInterval)
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
		return dataInterval
	}

	/**
	The `DataInterval` is the time that must elapse before the channel will fire another `HumidityChange` event.

	*   The data interval is bounded by `MinDataInterval` and `MaxDataInterval`.
	*   The timing between `HumidityChange` events can also be affected by the `HumidityChangeTrigger`.

	- throws:
	An error or type `PhidgetError`

	- parameters:
		- dataInterval: The data interval value
	*/
	public func setDataInterval(_ dataInterval: UInt32) throws {
		let result: PhidgetReturnCode
		result = PhidgetHumiditySensor_setDataInterval(chandle, dataInterval)
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
		result = PhidgetHumiditySensor_getMinDataInterval(chandle, &minDataInterval)
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
		result = PhidgetHumiditySensor_getMaxDataInterval(chandle, &maxDataInterval)
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
		result = PhidgetHumiditySensor_getDataRate(chandle, &dataRate)
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
		result = PhidgetHumiditySensor_setDataRate(chandle, dataRate)
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
		result = PhidgetHumiditySensor_getMinDataRate(chandle, &minDataRate)
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
		result = PhidgetHumiditySensor_getMaxDataRate(chandle, &maxDataRate)
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
		return maxDataRate
	}

	/**
	The most recent humidity value that the channel has reported.

	*   This value will always be between `MinHumidity` and `MaxHumidity`.

	- returns:
	The humidity value

	- throws:
	An error or type `PhidgetError`
	*/
	public func getHumidity() throws -> Double {
		let result: PhidgetReturnCode
		var humidity: Double = 0
		result = PhidgetHumiditySensor_getHumidity(chandle, &humidity)
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
		return humidity
	}

	/**
	The minimum value that the `HumidityChange` event will report.

	- returns:
	The humidity value

	- throws:
	An error or type `PhidgetError`
	*/
	public func getMinHumidity() throws -> Double {
		let result: PhidgetReturnCode
		var minHumidity: Double = 0
		result = PhidgetHumiditySensor_getMinHumidity(chandle, &minHumidity)
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
		return minHumidity
	}

	/**
	The maximum value that the `HumidityChange` event will report.

	- returns:
	The humidity value

	- throws:
	An error or type `PhidgetError`
	*/
	public func getMaxHumidity() throws -> Double {
		let result: PhidgetReturnCode
		var maxHumidity: Double = 0
		result = PhidgetHumiditySensor_getMaxHumidity(chandle, &maxHumidity)
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
		return maxHumidity
	}

	/**
	The channel will not issue a `HumidityChange` event until the humidity value has changed by the amount specified by the `HumidityChangeTrigger`.

	*   Setting the `HumidityChangeTrigger` to 0 will result in the channel firing events every `DataInterval`. This is useful for applications that implement their own data filtering.

	- returns:
	The change trigger value

	- throws:
	An error or type `PhidgetError`
	*/
	public func getHumidityChangeTrigger() throws -> Double {
		let result: PhidgetReturnCode
		var humidityChangeTrigger: Double = 0
		result = PhidgetHumiditySensor_getHumidityChangeTrigger(chandle, &humidityChangeTrigger)
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
		return humidityChangeTrigger
	}

	/**
	The channel will not issue a `HumidityChange` event until the humidity value has changed by the amount specified by the `HumidityChangeTrigger`.

	*   Setting the `HumidityChangeTrigger` to 0 will result in the channel firing events every `DataInterval`. This is useful for applications that implement their own data filtering.

	- throws:
	An error or type `PhidgetError`

	- parameters:
		- humidityChangeTrigger: The change trigger value
	*/
	public func setHumidityChangeTrigger(_ humidityChangeTrigger: Double) throws {
		let result: PhidgetReturnCode
		result = PhidgetHumiditySensor_setHumidityChangeTrigger(chandle, humidityChangeTrigger)
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
	}

	/**
	The minimum value that `HumidityChangeTrigger` can be set to.

	- returns:
	The change trigger value

	- throws:
	An error or type `PhidgetError`
	*/
	public func getMinHumidityChangeTrigger() throws -> Double {
		let result: PhidgetReturnCode
		var minHumidityChangeTrigger: Double = 0
		result = PhidgetHumiditySensor_getMinHumidityChangeTrigger(chandle, &minHumidityChangeTrigger)
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
		return minHumidityChangeTrigger
	}

	/**
	The maximum value that `HumidityChangeTrigger` can be set to.

	- returns:
	The change trigger value

	- throws:
	An error or type `PhidgetError`
	*/
	public func getMaxHumidityChangeTrigger() throws -> Double {
		let result: PhidgetReturnCode
		var maxHumidityChangeTrigger: Double = 0
		result = PhidgetHumiditySensor_getMaxHumidityChangeTrigger(chandle, &maxHumidityChangeTrigger)
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
		return maxHumidityChangeTrigger
	}

	internal override func initializeEvents() {
		initializeBaseEvents()
		PhidgetHumiditySensor_setOnHumidityChangeHandler(chandle, nativeHumidityChangeHandler, UnsafeMutableRawPointer(selfCtx!.toOpaque()))
	}

	internal override func uninitializeEvents() {
		uninitializeBaseEvents()
		PhidgetHumiditySensor_setOnHumidityChangeHandler(chandle, nil, nil)
	}

	/**
	The most recent humidity value the channel has measured will be reported in this event, which occurs when the `DataInterval` has elapsed.

	*   If a `HumidityChangeTrigger` has been set to a non-zero value, the `HumidityChange` event will not occur until the humidity has changed by at least the `HumidityChangeTrigger` value.

	---
	## Parameters:
	*   `humidity`: The ambient relative humidity
	*/
	public let humidityChange = Event<HumiditySensor, Double> ()
	let nativeHumidityChangeHandler : PhidgetHumiditySensor_OnHumidityChangeCallback = { ch, ctx, humidity in
		let me = Unmanaged<HumiditySensor>.fromOpaque(ctx!).takeUnretainedValue()
		me.humidityChange.raise(me, humidity);
	}

}
