import Foundation
//import Phidget22

/**
The Voltage Input class measures the voltage across the input of a Phidget with a voltage input. This may be a sensor designed to measure voltage directly, or it could be an input designed to interface with 0-5V sensors.

For 0-5V sensors, this class supports conversion to sensor data with units specific to the Phidget sensor being used, to make reading these sensors easy.
*/
public class VoltageInputBase : Phidget {

	public init() {
		var h: PhidgetHandle?
		PhidgetVoltageInput_create(&h)
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
			PhidgetVoltageInput_delete(&chandle)
		}
	}

	/**
	The `DataInterval` is the time that must elapse before the channel will fire another event.

	*   The data interval is bounded by `MinDataInterval` and `MaxDataInterval`.
	*   The timing between events can also be affected by the change trigger.

	- returns:
	The data interval value

	- throws:
	An error or type `PhidgetError`
	*/
	public func getDataInterval() throws -> UInt32 {
		let result: PhidgetReturnCode
		var dataInterval: UInt32 = 0
		result = PhidgetVoltageInput_getDataInterval(chandle, &dataInterval)
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
		return dataInterval
	}

	/**
	The `DataInterval` is the time that must elapse before the channel will fire another event.

	*   The data interval is bounded by `MinDataInterval` and `MaxDataInterval`.
	*   The timing between events can also be affected by the change trigger.

	- throws:
	An error or type `PhidgetError`

	- parameters:
		- dataInterval: The data interval value
	*/
	public func setDataInterval(_ dataInterval: UInt32) throws {
		let result: PhidgetReturnCode
		result = PhidgetVoltageInput_setDataInterval(chandle, dataInterval)
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
		result = PhidgetVoltageInput_getMinDataInterval(chandle, &minDataInterval)
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
		result = PhidgetVoltageInput_getMaxDataInterval(chandle, &maxDataInterval)
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
		result = PhidgetVoltageInput_getDataRate(chandle, &dataRate)
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
		result = PhidgetVoltageInput_setDataRate(chandle, dataRate)
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
		result = PhidgetVoltageInput_getMinDataRate(chandle, &minDataRate)
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
		result = PhidgetVoltageInput_getMaxDataRate(chandle, &maxDataRate)
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
		result = PhidgetVoltageInput_getPowerSupply(chandle, &powerSupply)
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
		result = PhidgetVoltageInput_setPowerSupply(chandle, Phidget_PowerSupply(powerSupply.rawValue))
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
	}

	/**
	We sell a variety of analog sensors that do not have their own API, they simply output a voltage that can be converted to a digital value using a specific formula. By matching the `SensorType` to your analog sensor, the correct formula will automatically be applied to data when you get the `SensorValue` or subscribe to the `SensorChange` event.

	*   The `SensorChange` event has its own change trigger associated with it: `SensorValueChangeTrigger`.
	*   Any data from getting the `SensorValue` or subscribing to the `SensorChange` event will have a `SensorUnit` associated with it.

	**Note:** Unlike other properties such as `Phidget.DeviceSerialNumber` or `Phidget.Channel`, `SensorType` is set after the device is opened, not before.

	- returns:
	The sensor type value

	- throws:
	An error or type `PhidgetError`
	*/
	public func getSensorType() throws -> VoltageSensorType {
		let result: PhidgetReturnCode
		var sensorType: PhidgetVoltageInput_SensorType = SENSOR_TYPE_VOLTAGE
		result = PhidgetVoltageInput_getSensorType(chandle, &sensorType)
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
		return VoltageSensorType(rawValue: sensorType.rawValue)!
	}

	/**
	We sell a variety of analog sensors that do not have their own API, they simply output a voltage that can be converted to a digital value using a specific formula. By matching the `SensorType` to your analog sensor, the correct formula will automatically be applied to data when you get the `SensorValue` or subscribe to the `SensorChange` event.

	*   The `SensorChange` event has its own change trigger associated with it: `SensorValueChangeTrigger`.
	*   Any data from getting the `SensorValue` or subscribing to the `SensorChange` event will have a `SensorUnit` associated with it.

	**Note:** Unlike other properties such as `Phidget.DeviceSerialNumber` or `Phidget.Channel`, `SensorType` is set after the device is opened, not before.

	- throws:
	An error or type `PhidgetError`

	- parameters:
		- sensorType: The sensor type value
	*/
	public func setSensorType(_ sensorType: VoltageSensorType) throws {
		let result: PhidgetReturnCode
		result = PhidgetVoltageInput_setSensorType(chandle, PhidgetVoltageInput_SensorType(sensorType.rawValue))
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
	}

	/**
	The unit of measurement that applies to the sensor values of the `SensorType` that has been selected.

	*   Helps keep track of the type of information being calculated from the voltage input.

	- returns:
	The sensor unit information corresponding to the `SensorValue`.

	- throws:
	An error or type `PhidgetError`
	*/
	public func getSensorUnit() throws -> UnitInfo {
		let result: PhidgetReturnCode
		var sensorUnit: Phidget_UnitInfo = Phidget_UnitInfo()
		result = PhidgetVoltageInput_getSensorUnit(chandle, &sensorUnit)
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
		return UnitInfo(sensorUnit)
	}

	/**
	The most recent sensor value that the channel has reported.

	*   Use `SensorUnit` to get the measurement units that are associated with the `SensorValue`

	- returns:
	The sensor value

	- throws:
	An error or type `PhidgetError`
	*/
	public func getSensorValue() throws -> Double {
		let result: PhidgetReturnCode
		var sensorValue: Double = 0
		result = PhidgetVoltageInput_getSensorValue(chandle, &sensorValue)
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
		return sensorValue
	}

	/**
	The channel will not issue a `SensorChange` event until the sensor value has changed by the amount specified by the `SensorValueChangeTrigger`.

	*   Setting the `SensorValueChangeTrigger` to 0 will result in the channel firing events every `DataInterval`. This is useful for applications that implement their own data filtering

	- returns:
	The change trigger value

	- throws:
	An error or type `PhidgetError`
	*/
	public func getSensorValueChangeTrigger() throws -> Double {
		let result: PhidgetReturnCode
		var sensorValueChangeTrigger: Double = 0
		result = PhidgetVoltageInput_getSensorValueChangeTrigger(chandle, &sensorValueChangeTrigger)
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
		return sensorValueChangeTrigger
	}

	/**
	The channel will not issue a `SensorChange` event until the sensor value has changed by the amount specified by the `SensorValueChangeTrigger`.

	*   Setting the `SensorValueChangeTrigger` to 0 will result in the channel firing events every `DataInterval`. This is useful for applications that implement their own data filtering

	- throws:
	An error or type `PhidgetError`

	- parameters:
		- sensorValueChangeTrigger: The change trigger value
	*/
	public func setSensorValueChangeTrigger(_ sensorValueChangeTrigger: Double) throws {
		let result: PhidgetReturnCode
		result = PhidgetVoltageInput_setSensorValueChangeTrigger(chandle, sensorValueChangeTrigger)
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
	}

	/**
	The most recent voltage value that the channel has reported.

	*   This value will always be between `MinVoltage` and `MaxVoltage`.

	- returns:
	The voltage value

	- throws:
	An error or type `PhidgetError`
	*/
	public func getVoltage() throws -> Double {
		let result: PhidgetReturnCode
		var voltage: Double = 0
		result = PhidgetVoltageInput_getVoltage(chandle, &voltage)
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
		return voltage
	}

	/**
	The minimum value the `VoltageChange` event will report.

	- returns:
	The voltage value

	- throws:
	An error or type `PhidgetError`
	*/
	public func getMinVoltage() throws -> Double {
		let result: PhidgetReturnCode
		var minVoltage: Double = 0
		result = PhidgetVoltageInput_getMinVoltage(chandle, &minVoltage)
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
		return minVoltage
	}

	/**
	The maximum value the `VoltageChange` event will report.

	- returns:
	The voltage value

	- throws:
	An error or type `PhidgetError`
	*/
	public func getMaxVoltage() throws -> Double {
		let result: PhidgetReturnCode
		var maxVoltage: Double = 0
		result = PhidgetVoltageInput_getMaxVoltage(chandle, &maxVoltage)
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
		return maxVoltage
	}

	/**
	The channel will not issue a `VoltageChange` event until the voltage value has changed by the amount specified by the `VoltageChangeTrigger`.

	*   Setting the `VoltageChangeTrigger` to 0 will result in the channel firing events every `DataInterval`. This is useful for applications that implement their own data filtering

	- returns:
	The change trigger value

	- throws:
	An error or type `PhidgetError`
	*/
	public func getVoltageChangeTrigger() throws -> Double {
		let result: PhidgetReturnCode
		var voltageChangeTrigger: Double = 0
		result = PhidgetVoltageInput_getVoltageChangeTrigger(chandle, &voltageChangeTrigger)
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
		return voltageChangeTrigger
	}

	/**
	The channel will not issue a `VoltageChange` event until the voltage value has changed by the amount specified by the `VoltageChangeTrigger`.

	*   Setting the `VoltageChangeTrigger` to 0 will result in the channel firing events every `DataInterval`. This is useful for applications that implement their own data filtering

	- throws:
	An error or type `PhidgetError`

	- parameters:
		- voltageChangeTrigger: The change trigger value
	*/
	public func setVoltageChangeTrigger(_ voltageChangeTrigger: Double) throws {
		let result: PhidgetReturnCode
		result = PhidgetVoltageInput_setVoltageChangeTrigger(chandle, voltageChangeTrigger)
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
	}

	/**
	The minimum value that `VoltageChangeTrigger` can be set to.

	- returns:
	The change trigger value

	- throws:
	An error or type `PhidgetError`
	*/
	public func getMinVoltageChangeTrigger() throws -> Double {
		let result: PhidgetReturnCode
		var minVoltageChangeTrigger: Double = 0
		result = PhidgetVoltageInput_getMinVoltageChangeTrigger(chandle, &minVoltageChangeTrigger)
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
		return minVoltageChangeTrigger
	}

	/**
	The maximum value that `VoltageChangeTrigger` can be set to.

	- returns:
	The change trigger value

	- throws:
	An error or type `PhidgetError`
	*/
	public func getMaxVoltageChangeTrigger() throws -> Double {
		let result: PhidgetReturnCode
		var maxVoltageChangeTrigger: Double = 0
		result = PhidgetVoltageInput_getMaxVoltageChangeTrigger(chandle, &maxVoltageChangeTrigger)
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
		return maxVoltageChangeTrigger
	}

	/**
	The voltage range you choose should allow you to measure the full range of your input signal.

	*   A larger `VoltageRange` equates to less resolution.
	*   If a `Saturation` event occurs, increase the voltage range.

	- returns:
	The voltage range value

	- throws:
	An error or type `PhidgetError`
	*/
	public func getVoltageRange() throws -> VoltageRange {
		let result: PhidgetReturnCode
		var voltageRange: PhidgetVoltageInput_VoltageRange = VOLTAGE_RANGE_10mV
		result = PhidgetVoltageInput_getVoltageRange(chandle, &voltageRange)
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
		return VoltageRange(rawValue: voltageRange.rawValue)!
	}

	/**
	The voltage range you choose should allow you to measure the full range of your input signal.

	*   A larger `VoltageRange` equates to less resolution.
	*   If a `Saturation` event occurs, increase the voltage range.

	- throws:
	An error or type `PhidgetError`

	- parameters:
		- voltageRange: The voltage range value
	*/
	public func setVoltageRange(_ voltageRange: VoltageRange) throws {
		let result: PhidgetReturnCode
		result = PhidgetVoltageInput_setVoltageRange(chandle, PhidgetVoltageInput_VoltageRange(voltageRange.rawValue))
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
	}

	internal override func initializeEvents() {
		initializeBaseEvents()
		PhidgetVoltageInput_setOnSensorChangeHandler(chandle, nativeSensorChangeHandler, UnsafeMutableRawPointer(selfCtx!.toOpaque()))
		PhidgetVoltageInput_setOnVoltageChangeHandler(chandle, nativeVoltageChangeHandler, UnsafeMutableRawPointer(selfCtx!.toOpaque()))
	}

	internal override func uninitializeEvents() {
		uninitializeBaseEvents()
		PhidgetVoltageInput_setOnSensorChangeHandler(chandle, nil, nil)
		PhidgetVoltageInput_setOnVoltageChangeHandler(chandle, nil, nil)
	}

	/**
	The most recent sensor value the channel has measured will be reported in this event, which occurs when the `DataInterval` has elapsed.

	*   If a `SensorValueChangeTrigger` has been set to a non-zero value, the `SensorChange` event will not occur until the sensor value has changed by at least the `SensorValueChangeTrigger` value.
	*   This event only fires when `SensorType` is not set to `VoltageSensorType.voltage`

	---
	## Parameters:
	*   `sensorValue`: The sensor value
	*   `sensorUnit`: The sensor unit information corresponding to the sensor value.

*   Helps keep track of the type of information being calculated from the voltage input.
	*/
	public let sensorChange = Event<VoltageInput, (sensorValue: Double, sensorUnit: UnitInfo)> ()
	let nativeSensorChangeHandler : PhidgetVoltageInput_OnSensorChangeCallback = { ch, ctx, sensorValue, sensorUnit in
		let me = Unmanaged<VoltageInput>.fromOpaque(ctx!).takeUnretainedValue()
		me.sensorChange.raise(me, (sensorValue, UnitInfo(sensorUnit!.pointee)));
	}

	/**
	The most recent voltage value the channel has measured will be reported in this event, which occurs when the `DataInterval` has elapsed.

	*   If a `VoltageChangeTrigger` has been set to a non-zero value, the `VoltageChange` event will not occur until the voltage has changed by at least the `VoltageChangeTrigger` value.
	*   If `SensorType` is supported and set to anything other then `VoltageSensorType.voltage`, this event will not fire.

	---
	## Parameters:
	*   `voltage`: Measured voltage
	*/
	public let voltageChange = Event<VoltageInput, Double> ()
	let nativeVoltageChangeHandler : PhidgetVoltageInput_OnVoltageChangeCallback = { ch, ctx, voltage in
		let me = Unmanaged<VoltageInput>.fromOpaque(ctx!).takeUnretainedValue()
		me.voltageChange.raise(me, voltage);
	}

}
