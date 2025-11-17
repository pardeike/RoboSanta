import Foundation
//import Phidget22

/**
The Temperature Sensor class gathers data from the temperature sensor on a Phidget board. This includes on-board ambient temperature sensors, connected thermocouples or platinum RTDs, and IR temperature sensors. This class is also used to measure the temperature on some high-power Phidget boards such as motor controllers for safety reasons.

If you're using a simple 0-5V sensor that does not have its own firmware, use the VoltageInput or VoltageRatioInput class instead, as specified for your device.
*/
public class TemperatureSensorBase : Phidget {

	public init() {
		var h: PhidgetHandle?
		PhidgetTemperatureSensor_create(&h)
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
			PhidgetTemperatureSensor_delete(&chandle)
		}
	}

	/**
	The `DataInterval` is the time that must elapse before the channel will fire another `TemperatureChange` event.

	*   The data interval is bounded by `MinDataInterval` and `MaxDataInterval`.
	*   The timing between `TemperatureChange` events can also be affected by the `TemperatureChangeTrigger`.

	- returns:
	The data interval value

	- throws:
	An error or type `PhidgetError`
	*/
	public func getDataInterval() throws -> UInt32 {
		let result: PhidgetReturnCode
		var dataInterval: UInt32 = 0
		result = PhidgetTemperatureSensor_getDataInterval(chandle, &dataInterval)
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
		return dataInterval
	}

	/**
	The `DataInterval` is the time that must elapse before the channel will fire another `TemperatureChange` event.

	*   The data interval is bounded by `MinDataInterval` and `MaxDataInterval`.
	*   The timing between `TemperatureChange` events can also be affected by the `TemperatureChangeTrigger`.

	- throws:
	An error or type `PhidgetError`

	- parameters:
		- dataInterval: The data interval value
	*/
	public func setDataInterval(_ dataInterval: UInt32) throws {
		let result: PhidgetReturnCode
		result = PhidgetTemperatureSensor_setDataInterval(chandle, dataInterval)
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
		result = PhidgetTemperatureSensor_getMinDataInterval(chandle, &minDataInterval)
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
		result = PhidgetTemperatureSensor_getMaxDataInterval(chandle, &maxDataInterval)
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
		result = PhidgetTemperatureSensor_getDataRate(chandle, &dataRate)
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
		result = PhidgetTemperatureSensor_setDataRate(chandle, dataRate)
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
		result = PhidgetTemperatureSensor_getMinDataRate(chandle, &minDataRate)
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
		result = PhidgetTemperatureSensor_getMaxDataRate(chandle, &maxDataRate)
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
		return maxDataRate
	}

	/**
	The `RTDType` must correspond to the RTD type you are using in your application.

	*   If you are unsure which `RTDType` to use, visit your device's User Guide for more information.

	- returns:
	The RTD type

	- throws:
	An error or type `PhidgetError`
	*/
	public func getRTDType() throws -> RTDType {
		let result: PhidgetReturnCode
		var rTDType: PhidgetTemperatureSensor_RTDType = RTD_TYPE_PT100_3850
		result = PhidgetTemperatureSensor_getRTDType(chandle, &rTDType)
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
		return RTDType(rawValue: rTDType.rawValue)!
	}

	/**
	The `RTDType` must correspond to the RTD type you are using in your application.

	*   If you are unsure which `RTDType` to use, visit your device's User Guide for more information.

	- throws:
	An error or type `PhidgetError`

	- parameters:
		- RTDType: The RTD type
	*/
	public func setRTDType(_ RTDType: RTDType) throws {
		let result: PhidgetReturnCode
		result = PhidgetTemperatureSensor_setRTDType(chandle, PhidgetTemperatureSensor_RTDType(RTDType.rawValue))
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
	}

	/**
	The `RTDWireSetup` must correspond to the wire configuration you are using in your application.

	*   If you are unsure which `RTDWireSetup` to use, visit your device's User Guide for more information.

	- returns:
	The RTD wire setup

	- throws:
	An error or type `PhidgetError`
	*/
	public func getRTDWireSetup() throws -> RTDWireSetup {
		let result: PhidgetReturnCode
		var rTDWireSetup: Phidget_RTDWireSetup = RTD_WIRE_SETUP_2WIRE
		result = PhidgetTemperatureSensor_getRTDWireSetup(chandle, &rTDWireSetup)
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
		return RTDWireSetup(rawValue: rTDWireSetup.rawValue)!
	}

	/**
	The `RTDWireSetup` must correspond to the wire configuration you are using in your application.

	*   If you are unsure which `RTDWireSetup` to use, visit your device's User Guide for more information.

	- throws:
	An error or type `PhidgetError`

	- parameters:
		- RTDWireSetup: The RTD wire setup
	*/
	public func setRTDWireSetup(_ RTDWireSetup: RTDWireSetup) throws {
		let result: PhidgetReturnCode
		result = PhidgetTemperatureSensor_setRTDWireSetup(chandle, Phidget_RTDWireSetup(RTDWireSetup.rawValue))
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
	}

	/**
	The most recent temperature value that the channel has reported.

	*   This value will always be between `MinTemperature` and `MaxTemperature`.

	- returns:
	The temperature value

	- throws:
	An error or type `PhidgetError`
	*/
	public func getTemperature() throws -> Double {
		let result: PhidgetReturnCode
		var temperature: Double = 0
		result = PhidgetTemperatureSensor_getTemperature(chandle, &temperature)
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
		return temperature
	}

	/**
	The minimum value the `TemperatureChange` event will report.

	- returns:
	The temperature value

	- throws:
	An error or type `PhidgetError`
	*/
	public func getMinTemperature() throws -> Double {
		let result: PhidgetReturnCode
		var minTemperature: Double = 0
		result = PhidgetTemperatureSensor_getMinTemperature(chandle, &minTemperature)
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
		return minTemperature
	}

	/**
	The maximum value the `TemperatureChange` event will report.

	- returns:
	The temperature value

	- throws:
	An error or type `PhidgetError`
	*/
	public func getMaxTemperature() throws -> Double {
		let result: PhidgetReturnCode
		var maxTemperature: Double = 0
		result = PhidgetTemperatureSensor_getMaxTemperature(chandle, &maxTemperature)
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
		return maxTemperature
	}

	/**
	The channel will not issue a `TemperatureChange` event until the temperature value has changed by the amount specified by the `TemperatureChangeTrigger`.

	*   Setting the `TemperatureChangeTrigger` to 0 will result in the channel firing events every `DataInterval`. This is useful for applications that implement their own data filtering

	- returns:
	The change trigger value

	- throws:
	An error or type `PhidgetError`
	*/
	public func getTemperatureChangeTrigger() throws -> Double {
		let result: PhidgetReturnCode
		var temperatureChangeTrigger: Double = 0
		result = PhidgetTemperatureSensor_getTemperatureChangeTrigger(chandle, &temperatureChangeTrigger)
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
		return temperatureChangeTrigger
	}

	/**
	The channel will not issue a `TemperatureChange` event until the temperature value has changed by the amount specified by the `TemperatureChangeTrigger`.

	*   Setting the `TemperatureChangeTrigger` to 0 will result in the channel firing events every `DataInterval`. This is useful for applications that implement their own data filtering

	- throws:
	An error or type `PhidgetError`

	- parameters:
		- temperatureChangeTrigger: The change trigger value
	*/
	public func setTemperatureChangeTrigger(_ temperatureChangeTrigger: Double) throws {
		let result: PhidgetReturnCode
		result = PhidgetTemperatureSensor_setTemperatureChangeTrigger(chandle, temperatureChangeTrigger)
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
	}

	/**
	The minimum value that `TemperatureChangeTrigger` can be set to.

	- returns:
	The change trigger value

	- throws:
	An error or type `PhidgetError`
	*/
	public func getMinTemperatureChangeTrigger() throws -> Double {
		let result: PhidgetReturnCode
		var minTemperatureChangeTrigger: Double = 0
		result = PhidgetTemperatureSensor_getMinTemperatureChangeTrigger(chandle, &minTemperatureChangeTrigger)
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
		return minTemperatureChangeTrigger
	}

	/**
	The maximum value that `TemperatureChangeTrigger` can be set to.

	- returns:
	The change trigger value

	- throws:
	An error or type `PhidgetError`
	*/
	public func getMaxTemperatureChangeTrigger() throws -> Double {
		let result: PhidgetReturnCode
		var maxTemperatureChangeTrigger: Double = 0
		result = PhidgetTemperatureSensor_getMaxTemperatureChangeTrigger(chandle, &maxTemperatureChangeTrigger)
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
		return maxTemperatureChangeTrigger
	}

	/**
	The `ThermocoupleType` must correspond to the thermocouple type you are using in your application.

	*   If you are unsure which `ThermocoupleType` to use, visit the [Thermocouple Primer](https://www.phidgets.com/docs/Thermocouple_Primer) for more information.

	- returns:
	The thermocouple type

	- throws:
	An error or type `PhidgetError`
	*/
	public func getThermocoupleType() throws -> ThermocoupleType {
		let result: PhidgetReturnCode
		var thermocoupleType: PhidgetTemperatureSensor_ThermocoupleType = THERMOCOUPLE_TYPE_J
		result = PhidgetTemperatureSensor_getThermocoupleType(chandle, &thermocoupleType)
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
		return ThermocoupleType(rawValue: thermocoupleType.rawValue)!
	}

	/**
	The `ThermocoupleType` must correspond to the thermocouple type you are using in your application.

	*   If you are unsure which `ThermocoupleType` to use, visit the [Thermocouple Primer](https://www.phidgets.com/docs/Thermocouple_Primer) for more information.

	- throws:
	An error or type `PhidgetError`

	- parameters:
		- thermocoupleType: The thermocouple type
	*/
	public func setThermocoupleType(_ thermocoupleType: ThermocoupleType) throws {
		let result: PhidgetReturnCode
		result = PhidgetTemperatureSensor_setThermocoupleType(chandle, PhidgetTemperatureSensor_ThermocoupleType(thermocoupleType.rawValue))
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
	}

	internal override func initializeEvents() {
		initializeBaseEvents()
		PhidgetTemperatureSensor_setOnTemperatureChangeHandler(chandle, nativeTemperatureChangeHandler, UnsafeMutableRawPointer(selfCtx!.toOpaque()))
	}

	internal override func uninitializeEvents() {
		uninitializeBaseEvents()
		PhidgetTemperatureSensor_setOnTemperatureChangeHandler(chandle, nil, nil)
	}

	/**
	The most recent temperature value the channel has measured will be reported in this event, which occurs when the `DataInterval` has elapsed.

	*   If a `TemperatureChangeTrigger` has been set to a non-zero value, the `TemperatureChange` event will not occur until the temperature has changed by at least the `TemperatureChangeTrigger` value.

	---
	## Parameters:
	*   `temperature`: The temperature
	*/
	public let temperatureChange = Event<TemperatureSensor, Double> ()
	let nativeTemperatureChangeHandler : PhidgetTemperatureSensor_OnTemperatureChangeCallback = { ch, ctx, temperature in
		let me = Unmanaged<TemperatureSensor>.fromOpaque(ctx!).takeUnretainedValue()
		me.temperatureChange.raise(me, temperature);
	}

}
