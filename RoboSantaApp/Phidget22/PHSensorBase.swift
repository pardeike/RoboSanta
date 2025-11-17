import Foundation
//import Phidget22

/**
The PH Sensor class gathers data from a pH sensor type Phidget board.

If you're using a simple 0-5V sensor that does not have its own firmware, use the VoltageInput or VoltageRatioInput class instead, as specified for your device.
*/
public class PHSensorBase : Phidget {

	public init() {
		var h: PhidgetHandle?
		PhidgetPHSensor_create(&h)
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
			PhidgetPHSensor_delete(&chandle)
		}
	}

	/**
	Set this property to the measured temperature of the solution to correct the slope of the pH conversion for temperature.

	- returns:
	The temperature of the solution to correct the pH measurement.

	- throws:
	An error or type `PhidgetError`
	*/
	public func getCorrectionTemperature() throws -> Double {
		let result: PhidgetReturnCode
		var correctionTemperature: Double = 0
		result = PhidgetPHSensor_getCorrectionTemperature(chandle, &correctionTemperature)
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
		return correctionTemperature
	}

	/**
	Set this property to the measured temperature of the solution to correct the slope of the pH conversion for temperature.

	- throws:
	An error or type `PhidgetError`

	- parameters:
		- correctionTemperature: The temperature of the solution to correct the pH measurement.
	*/
	public func setCorrectionTemperature(_ correctionTemperature: Double) throws {
		let result: PhidgetReturnCode
		result = PhidgetPHSensor_setCorrectionTemperature(chandle, correctionTemperature)
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
	}

	/**
	The minimum value that `CorrectionTemperature` can be set to.

	- returns:
	The minimum temperature that can be corrected for.

	- throws:
	An error or type `PhidgetError`
	*/
	public func getMinCorrectionTemperature() throws -> Double {
		let result: PhidgetReturnCode
		var minCorrectionTemperature: Double = 0
		result = PhidgetPHSensor_getMinCorrectionTemperature(chandle, &minCorrectionTemperature)
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
		return minCorrectionTemperature
	}

	/**
	The maximum value that `CorrectionTemperature` can be set to.

	- returns:
	The maximum temperature that can be corrected for.

	- throws:
	An error or type `PhidgetError`
	*/
	public func getMaxCorrectionTemperature() throws -> Double {
		let result: PhidgetReturnCode
		var maxCorrectionTemperature: Double = 0
		result = PhidgetPHSensor_getMaxCorrectionTemperature(chandle, &maxCorrectionTemperature)
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
		return maxCorrectionTemperature
	}

	/**
	The `DataInterval` is the time that must elapse before the channel will fire another `PHChange` event.

	*   The data interval is bounded by `MinDataInterval` and `MaxDataInterval`.
	*   The timing between `PHChange` events can also be affected by the `PHChangeTrigger`.

	- returns:
	The data interval value

	- throws:
	An error or type `PhidgetError`
	*/
	public func getDataInterval() throws -> UInt32 {
		let result: PhidgetReturnCode
		var dataInterval: UInt32 = 0
		result = PhidgetPHSensor_getDataInterval(chandle, &dataInterval)
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
		return dataInterval
	}

	/**
	The `DataInterval` is the time that must elapse before the channel will fire another `PHChange` event.

	*   The data interval is bounded by `MinDataInterval` and `MaxDataInterval`.
	*   The timing between `PHChange` events can also be affected by the `PHChangeTrigger`.

	- throws:
	An error or type `PhidgetError`

	- parameters:
		- dataInterval: The data interval value
	*/
	public func setDataInterval(_ dataInterval: UInt32) throws {
		let result: PhidgetReturnCode
		result = PhidgetPHSensor_setDataInterval(chandle, dataInterval)
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
		result = PhidgetPHSensor_getMinDataInterval(chandle, &minDataInterval)
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
		result = PhidgetPHSensor_getMaxDataInterval(chandle, &maxDataInterval)
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
		result = PhidgetPHSensor_getDataRate(chandle, &dataRate)
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
		result = PhidgetPHSensor_setDataRate(chandle, dataRate)
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
		result = PhidgetPHSensor_getMinDataRate(chandle, &minDataRate)
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
		result = PhidgetPHSensor_getMaxDataRate(chandle, &maxDataRate)
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
		return maxDataRate
	}

	/**
	The most recent pH value that the channel has reported.

	*   This value will always be between `MinPH` and `MaxPH`.

	- returns:
	The pH value

	- throws:
	An error or type `PhidgetError`
	*/
	public func getPH() throws -> Double {
		let result: PhidgetReturnCode
		var pH: Double = 0
		result = PhidgetPHSensor_getPH(chandle, &pH)
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
		return pH
	}

	/**
	The minimum value the `PHChange` event will report.

	- returns:
	The pH value

	- throws:
	An error or type `PhidgetError`
	*/
	public func getMinPH() throws -> Double {
		let result: PhidgetReturnCode
		var minPH: Double = 0
		result = PhidgetPHSensor_getMinPH(chandle, &minPH)
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
		return minPH
	}

	/**
	The maximum value the `PHChange` event will report.

	- returns:
	The pH value

	- throws:
	An error or type `PhidgetError`
	*/
	public func getMaxPH() throws -> Double {
		let result: PhidgetReturnCode
		var maxPH: Double = 0
		result = PhidgetPHSensor_getMaxPH(chandle, &maxPH)
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
		return maxPH
	}

	/**
	The channel will not issue a `PHChange` event until the pH value has changed by the amount specified by the `PHChangeTrigger`.

	*   Setting the `PHChangeTrigger` to 0 will result in the channel firing events every `DataInterval`. This is useful for applications that implement their own data filtering

	- returns:
	The change trigger value

	- throws:
	An error or type `PhidgetError`
	*/
	public func getPHChangeTrigger() throws -> Double {
		let result: PhidgetReturnCode
		var pHChangeTrigger: Double = 0
		result = PhidgetPHSensor_getPHChangeTrigger(chandle, &pHChangeTrigger)
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
		return pHChangeTrigger
	}

	/**
	The channel will not issue a `PHChange` event until the pH value has changed by the amount specified by the `PHChangeTrigger`.

	*   Setting the `PHChangeTrigger` to 0 will result in the channel firing events every `DataInterval`. This is useful for applications that implement their own data filtering

	- throws:
	An error or type `PhidgetError`

	- parameters:
		- PHChangeTrigger: The change trigger value
	*/
	public func setPHChangeTrigger(_ PHChangeTrigger: Double) throws {
		let result: PhidgetReturnCode
		result = PhidgetPHSensor_setPHChangeTrigger(chandle, PHChangeTrigger)
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
	}

	/**
	The minimum value that `PHChangeTrigger` can be set to.

	- returns:
	The change trigger value

	- throws:
	An error or type `PhidgetError`
	*/
	public func getMinPHChangeTrigger() throws -> Double {
		let result: PhidgetReturnCode
		var minPHChangeTrigger: Double = 0
		result = PhidgetPHSensor_getMinPHChangeTrigger(chandle, &minPHChangeTrigger)
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
		return minPHChangeTrigger
	}

	/**
	The maximum value that `PHChangeTrigger` can be set to.

	- returns:
	The change trigger value

	- throws:
	An error or type `PhidgetError`
	*/
	public func getMaxPHChangeTrigger() throws -> Double {
		let result: PhidgetReturnCode
		var maxPHChangeTrigger: Double = 0
		result = PhidgetPHSensor_getMaxPHChangeTrigger(chandle, &maxPHChangeTrigger)
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
		return maxPHChangeTrigger
	}

	internal override func initializeEvents() {
		initializeBaseEvents()
		PhidgetPHSensor_setOnPHChangeHandler(chandle, nativePHChangeHandler, UnsafeMutableRawPointer(selfCtx!.toOpaque()))
	}

	internal override func uninitializeEvents() {
		uninitializeBaseEvents()
		PhidgetPHSensor_setOnPHChangeHandler(chandle, nil, nil)
	}

	/**
	The most recent pH value the channel has measured will be reported in this event, which occurs when the `DataInterval` has elapsed.

	*   If a `PHChangeTrigger` has been set to a non-zero value, the `PHChange` event will not occur until the pH has changed by at least the `PHChangeTrigger` value.

	---
	## Parameters:
	*   `PH`: The current pH
	*/
	public let PHChange = Event<PHSensor, Double> ()
	let nativePHChangeHandler : PhidgetPHSensor_OnPHChangeCallback = { ch, ctx, PH in
		let me = Unmanaged<PHSensor>.fromOpaque(ctx!).takeUnretainedValue()
		me.PHChange.raise(me, PH);
	}

}
