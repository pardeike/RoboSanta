import Foundation
//import Phidget22

/**
The Voltage Ratio Input class is used for measuring the ratio between the voltage supplied to and the voltage returned from an attached sensor or device. This is useful for interfacing with ratiometric sensors or wheatstone bridge based sensors.

For ratiometric sensors, this class supports conversion to sensor data with units specific to the Phidget sensor being used, to make reading these sensors easy.
*/
public class VoltageRatioInputBase : Phidget {

	public init() {
		var h: PhidgetHandle?
		PhidgetVoltageRatioInput_create(&h)
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
			PhidgetVoltageRatioInput_delete(&chandle)
		}
	}

	/**
	Enable power to the input and start collecting data by setting `BridgeEnabled` to true.

	- returns:
	The enabled value

	- throws:
	An error or type `PhidgetError`
	*/
	public func getBridgeEnabled() throws -> Bool {
		let result: PhidgetReturnCode
		var bridgeEnabled: Int32 = 0
		result = PhidgetVoltageRatioInput_getBridgeEnabled(chandle, &bridgeEnabled)
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
		return (bridgeEnabled == 0 ? false : true)
	}

	/**
	Enable power to the input and start collecting data by setting `BridgeEnabled` to true.

	- throws:
	An error or type `PhidgetError`

	- parameters:
		- bridgeEnabled: The enabled value
	*/
	public func setBridgeEnabled(_ bridgeEnabled: Bool) throws {
		let result: PhidgetReturnCode
		result = PhidgetVoltageRatioInput_setBridgeEnabled(chandle, (bridgeEnabled ? 1 : 0))
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
	}

	/**
	Choose a `BridgeGain` that best suits your application.

	*   For more information about the range and accuracy of each `BridgeGain` to decide which best suits your application, see your device's User Guide.

	- returns:
	The bridge gain value

	- throws:
	An error or type `PhidgetError`
	*/
	public func getBridgeGain() throws -> BridgeGain {
		let result: PhidgetReturnCode
		var bridgeGain: PhidgetVoltageRatioInput_BridgeGain = BRIDGE_GAIN_1
		result = PhidgetVoltageRatioInput_getBridgeGain(chandle, &bridgeGain)
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
		return BridgeGain(rawValue: bridgeGain.rawValue)!
	}

	/**
	Choose a `BridgeGain` that best suits your application.

	*   For more information about the range and accuracy of each `BridgeGain` to decide which best suits your application, see your device's User Guide.

	- throws:
	An error or type `PhidgetError`

	- parameters:
		- bridgeGain: The bridge gain value
	*/
	public func setBridgeGain(_ bridgeGain: BridgeGain) throws {
		let result: PhidgetReturnCode
		result = PhidgetVoltageRatioInput_setBridgeGain(chandle, PhidgetVoltageRatioInput_BridgeGain(bridgeGain.rawValue))
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
	}

	/**
	The `DataInterval` is the time that must elapse before the channel will fire another event.

	*   The data interval is bounded by `MinDataInterval` and `MaxDataInterval`.
	*   The timing between events can also be affected by the change trigger.

	- returns:
	The data interval for the channel

	- throws:
	An error or type `PhidgetError`
	*/
	public func getDataInterval() throws -> UInt32 {
		let result: PhidgetReturnCode
		var dataInterval: UInt32 = 0
		result = PhidgetVoltageRatioInput_getDataInterval(chandle, &dataInterval)
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
		- dataInterval: The data interval for the channel
	*/
	public func setDataInterval(_ dataInterval: UInt32) throws {
		let result: PhidgetReturnCode
		result = PhidgetVoltageRatioInput_setDataInterval(chandle, dataInterval)
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
		result = PhidgetVoltageRatioInput_getMinDataInterval(chandle, &minDataInterval)
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
		result = PhidgetVoltageRatioInput_getMaxDataInterval(chandle, &maxDataInterval)
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
		result = PhidgetVoltageRatioInput_getDataRate(chandle, &dataRate)
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
		result = PhidgetVoltageRatioInput_setDataRate(chandle, dataRate)
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
		result = PhidgetVoltageRatioInput_getMinDataRate(chandle, &minDataRate)
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
		result = PhidgetVoltageRatioInput_getMaxDataRate(chandle, &maxDataRate)
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
		return maxDataRate
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
	public func getSensorType() throws -> VoltageRatioSensorType {
		let result: PhidgetReturnCode
		var sensorType: PhidgetVoltageRatioInput_SensorType = SENSOR_TYPE_VOLTAGERATIO
		result = PhidgetVoltageRatioInput_getSensorType(chandle, &sensorType)
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
		return VoltageRatioSensorType(rawValue: sensorType.rawValue)!
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
	public func setSensorType(_ sensorType: VoltageRatioSensorType) throws {
		let result: PhidgetReturnCode
		result = PhidgetVoltageRatioInput_setSensorType(chandle, PhidgetVoltageRatioInput_SensorType(sensorType.rawValue))
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
	}

	/**
	The unit of measurement that applies to the sensor values of the `SensorType` that has been selected.

	*   Helps keep track of the type of information being calculated from the voltage ratio input.

	- returns:
	The sensor unit information corresponding to the `SensorValue`.

	- throws:
	An error or type `PhidgetError`
	*/
	public func getSensorUnit() throws -> UnitInfo {
		let result: PhidgetReturnCode
		var sensorUnit: Phidget_UnitInfo = Phidget_UnitInfo()
		result = PhidgetVoltageRatioInput_getSensorUnit(chandle, &sensorUnit)
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
		result = PhidgetVoltageRatioInput_getSensorValue(chandle, &sensorValue)
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
		result = PhidgetVoltageRatioInput_getSensorValueChangeTrigger(chandle, &sensorValueChangeTrigger)
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
		result = PhidgetVoltageRatioInput_setSensorValueChangeTrigger(chandle, sensorValueChangeTrigger)
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
	}

	/**
	The most recent voltage ratio value that the channel has reported.

	*   This value will always be between `MinVoltageRatio` and `MaxVoltageRatio`.

	- returns:
	The voltage ratio value

	- throws:
	An error or type `PhidgetError`
	*/
	public func getVoltageRatio() throws -> Double {
		let result: PhidgetReturnCode
		var voltageRatio: Double = 0
		result = PhidgetVoltageRatioInput_getVoltageRatio(chandle, &voltageRatio)
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
		return voltageRatio
	}

	/**
	The minimum value the `VoltageRatioChange` event will report.

	- returns:
	The voltage ratio value

	- throws:
	An error or type `PhidgetError`
	*/
	public func getMinVoltageRatio() throws -> Double {
		let result: PhidgetReturnCode
		var minVoltageRatio: Double = 0
		result = PhidgetVoltageRatioInput_getMinVoltageRatio(chandle, &minVoltageRatio)
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
		return minVoltageRatio
	}

	/**
	The maximum value the `VoltageRatioChange` event will report.

	- returns:
	The voltage ratio value

	- throws:
	An error or type `PhidgetError`
	*/
	public func getMaxVoltageRatio() throws -> Double {
		let result: PhidgetReturnCode
		var maxVoltageRatio: Double = 0
		result = PhidgetVoltageRatioInput_getMaxVoltageRatio(chandle, &maxVoltageRatio)
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
		return maxVoltageRatio
	}

	/**
	The channel will not issue a `VoltageRatioChange` event until the voltage ratio value has changed by the amount specified by the `VoltageRatioChangeTrigger`.

	*   Setting the `VoltageRatioChangeTrigger` to 0 will result in the channel firing events every `DataInterval`. This is useful for applications that implement their own data filtering

	- returns:
	The change trigger value

	- throws:
	An error or type `PhidgetError`
	*/
	public func getVoltageRatioChangeTrigger() throws -> Double {
		let result: PhidgetReturnCode
		var voltageRatioChangeTrigger: Double = 0
		result = PhidgetVoltageRatioInput_getVoltageRatioChangeTrigger(chandle, &voltageRatioChangeTrigger)
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
		return voltageRatioChangeTrigger
	}

	/**
	The channel will not issue a `VoltageRatioChange` event until the voltage ratio value has changed by the amount specified by the `VoltageRatioChangeTrigger`.

	*   Setting the `VoltageRatioChangeTrigger` to 0 will result in the channel firing events every `DataInterval`. This is useful for applications that implement their own data filtering

	- throws:
	An error or type `PhidgetError`

	- parameters:
		- voltageRatioChangeTrigger: The change trigger value
	*/
	public func setVoltageRatioChangeTrigger(_ voltageRatioChangeTrigger: Double) throws {
		let result: PhidgetReturnCode
		result = PhidgetVoltageRatioInput_setVoltageRatioChangeTrigger(chandle, voltageRatioChangeTrigger)
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
	}

	/**
	The minimum value that `VoltageRatioChangeTrigger` can be set to.

	- returns:
	The change trigger value

	- throws:
	An error or type `PhidgetError`
	*/
	public func getMinVoltageRatioChangeTrigger() throws -> Double {
		let result: PhidgetReturnCode
		var minVoltageRatioChangeTrigger: Double = 0
		result = PhidgetVoltageRatioInput_getMinVoltageRatioChangeTrigger(chandle, &minVoltageRatioChangeTrigger)
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
		return minVoltageRatioChangeTrigger
	}

	/**
	The maximum value that `VoltageRatioChangeTrigger` can be set to.

	- returns:
	The change trigger value

	- throws:
	An error or type `PhidgetError`
	*/
	public func getMaxVoltageRatioChangeTrigger() throws -> Double {
		let result: PhidgetReturnCode
		var maxVoltageRatioChangeTrigger: Double = 0
		result = PhidgetVoltageRatioInput_getMaxVoltageRatioChangeTrigger(chandle, &maxVoltageRatioChangeTrigger)
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
		return maxVoltageRatioChangeTrigger
	}

	internal override func initializeEvents() {
		initializeBaseEvents()
		PhidgetVoltageRatioInput_setOnSensorChangeHandler(chandle, nativeSensorChangeHandler, UnsafeMutableRawPointer(selfCtx!.toOpaque()))
		PhidgetVoltageRatioInput_setOnVoltageRatioChangeHandler(chandle, nativeVoltageRatioChangeHandler, UnsafeMutableRawPointer(selfCtx!.toOpaque()))
	}

	internal override func uninitializeEvents() {
		uninitializeBaseEvents()
		PhidgetVoltageRatioInput_setOnSensorChangeHandler(chandle, nil, nil)
		PhidgetVoltageRatioInput_setOnVoltageRatioChangeHandler(chandle, nil, nil)
	}

	/**
	The most recent sensor value the channel has measured will be reported in this event, which occurs when the `DataInterval` has elapsed.

	*   If a `SensorValueChangeTrigger` has been set to a non-zero value, the `SensorChange` event will not occur until the sensor value has changed by at least the `SensorValueChangeTrigger` value.
	*   This event only fires when `SensorType` is not set to `VoltageRatioSensorType.voltageRatio`

	---
	## Parameters:
	*   `sensorValue`: The sensor value
	*   `sensorUnit`: The sensor unit information corresponding to the `SensorValue`.

*   Helps keep track of the type of information being calculated from the voltage ratio input.
	*/
	public let sensorChange = Event<VoltageRatioInput, (sensorValue: Double, sensorUnit: UnitInfo)> ()
	let nativeSensorChangeHandler : PhidgetVoltageRatioInput_OnSensorChangeCallback = { ch, ctx, sensorValue, sensorUnit in
		let me = Unmanaged<VoltageRatioInput>.fromOpaque(ctx!).takeUnretainedValue()
		me.sensorChange.raise(me, (sensorValue, UnitInfo(sensorUnit!.pointee)));
	}

	/**
	The most recent voltage ratio value the channel has measured will be reported in this event, which occurs when the `DataInterval` has elapsed.

	*   If a `VoltageRatioChangeTrigger` has been set to a non-zero value, the `VoltageRatioChange` event will not occur until the voltage has changed by at least the `VoltageRatioChangeTrigger` value.
	*   If `SensorType` is supported and set to anything other than `VoltageRatioSensorType.voltageRatio`, this event will not fire.

	---
	## Parameters:
	*   `voltageRatio`: The voltage ratio
	*/
	public let voltageRatioChange = Event<VoltageRatioInput, Double> ()
	let nativeVoltageRatioChangeHandler : PhidgetVoltageRatioInput_OnVoltageRatioChangeCallback = { ch, ctx, voltageRatio in
		let me = Unmanaged<VoltageRatioInput>.fromOpaque(ctx!).takeUnretainedValue()
		me.voltageRatioChange.raise(me, voltageRatio);
	}

}
