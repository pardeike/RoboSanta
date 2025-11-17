import Foundation
//import Phidget22

/**
The Sound Sensor class gathers data from the sound sensor on a Phidget board.

If you're using a simple 0-5V sensor that does not have its own firmware, use the VoltageInput or VoltageRatioInput class instead, as specified for your device.
*/
public class SoundSensorBase : Phidget {

	public init() {
		var h: PhidgetHandle?
		PhidgetSoundSensor_create(&h)
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
			PhidgetSoundSensor_delete(&chandle)
		}
	}

	/**
	The `DataInterval` is the time that must elapse before the channel will fire another `SPLChange` event.

	*   The data interval is bounded by `MinDataInterval` and `MaxDataInterval`.
	*   The timing between `SPLChange` events can also be affected by the `SPLChangeTrigger`.

	- returns:
	The data interval value

	- throws:
	An error or type `PhidgetError`
	*/
	public func getDataInterval() throws -> UInt32 {
		let result: PhidgetReturnCode
		var dataInterval: UInt32 = 0
		result = PhidgetSoundSensor_getDataInterval(chandle, &dataInterval)
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
		return dataInterval
	}

	/**
	The `DataInterval` is the time that must elapse before the channel will fire another `SPLChange` event.

	*   The data interval is bounded by `MinDataInterval` and `MaxDataInterval`.
	*   The timing between `SPLChange` events can also be affected by the `SPLChangeTrigger`.

	- throws:
	An error or type `PhidgetError`

	- parameters:
		- dataInterval: The data interval value
	*/
	public func setDataInterval(_ dataInterval: UInt32) throws {
		let result: PhidgetReturnCode
		result = PhidgetSoundSensor_setDataInterval(chandle, dataInterval)
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
		result = PhidgetSoundSensor_getMinDataInterval(chandle, &minDataInterval)
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
		result = PhidgetSoundSensor_getMaxDataInterval(chandle, &maxDataInterval)
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
		result = PhidgetSoundSensor_getDataRate(chandle, &dataRate)
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
		result = PhidgetSoundSensor_setDataRate(chandle, dataRate)
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
		result = PhidgetSoundSensor_getMinDataRate(chandle, &minDataRate)
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
		result = PhidgetSoundSensor_getMaxDataRate(chandle, &maxDataRate)
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
		return maxDataRate
	}

	/**
	The most recent dB SPL value that has been calculated.

	*   This value is bounded by `MaxdB`.

	- returns:
	The dB value

	- throws:
	An error or type `PhidgetError`
	*/
	public func getdB() throws -> Double {
		let result: PhidgetReturnCode
		var dB: Double = 0
		result = PhidgetSoundSensor_getdB(chandle, &dB)
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
		return dB
	}

	/**
	The most recent dBA SPL value that has been calculated.

	*   The dBA SPL value is calculated by applying a A-weighted filter to the `Octaves` data.

	- returns:
	The dBA value

	- throws:
	An error or type `PhidgetError`
	*/
	public func getdBA() throws -> Double {
		let result: PhidgetReturnCode
		var dBA: Double = 0
		result = PhidgetSoundSensor_getdBA(chandle, &dBA)
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
		return dBA
	}

	/**
	The most recent dBC SPL value that has been calculated.

	*   The dBC SPL value is calculated by applying a C-weighted filter to the `Octaves` data.

	- returns:
	The dBC value

	- throws:
	An error or type `PhidgetError`
	*/
	public func getdBC() throws -> Double {
		let result: PhidgetReturnCode
		var dBC: Double = 0
		result = PhidgetSoundSensor_getdBC(chandle, &dBC)
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
		return dBC
	}

	/**
	The maximum value the `SPLChange` event will report.

	- returns:
	The dB value

	- throws:
	An error or type `PhidgetError`
	*/
	public func getMaxdB() throws -> Double {
		let result: PhidgetReturnCode
		var maxdB: Double = 0
		result = PhidgetSoundSensor_getMaxdB(chandle, &maxdB)
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
		return maxdB
	}

	/**
	The minimum SPL value that the channel can accurately measure.

	*   Input SPLs below this level will not produce an output from the microphone.

	- returns:
	The noise floor value.

	- throws:
	An error or type `PhidgetError`
	*/
	public func getNoiseFloor() throws -> Double {
		let result: PhidgetReturnCode
		var noiseFloor: Double = 0
		result = PhidgetSoundSensor_getNoiseFloor(chandle, &noiseFloor)
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
		return noiseFloor
	}

	/**
	The unweighted value of each frequency band.

	*   The following frequency bands are represented:

	*   octaves\[0\] = 31.5 Hz
	*   octaves\[1\] = 63 Hz
	*   octaves\[2\] = 125 Hz
	*   octaves\[3\] = 250 Hz
	*   octaves\[4\] = 500 Hz
	*   octaves\[5\] = 1 kHz
	*   octaves\[6\] = 2 kHz
	*   octaves\[7\] = 4 kHz
	*   octaves\[8\] = 8 kHz
	*   octaves\[9\] = 16 kHz

	- returns:
	The octave values

	- throws:
	An error or type `PhidgetError`
	*/
	public func getOctaves() throws -> [Double] {
		let result: PhidgetReturnCode
		var octaves: (Double, Double, Double, Double, Double, Double, Double, Double, Double, Double) = (0, 0, 0, 0, 0, 0, 0, 0, 0, 0)
		result = PhidgetSoundSensor_getOctaves(chandle, &octaves)
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
		return [octaves.0, octaves.1, octaves.2, octaves.3, octaves.4, octaves.5, octaves.6, octaves.7, octaves.8, octaves.9]
	}

	/**
	The channel will not issue a `SPLChange` event until the `dB` value has changed by the amount specified by the `SPLChangeTrigger`.

	*   Setting the `SPLChangeTrigger` to 0 will result in the channel firing events every `DataInterval`. This is useful for applications that implement their own data filtering

	- returns:
	The change trigger value

	- throws:
	An error or type `PhidgetError`
	*/
	public func getSPLChangeTrigger() throws -> Double {
		let result: PhidgetReturnCode
		var sPLChangeTrigger: Double = 0
		result = PhidgetSoundSensor_getSPLChangeTrigger(chandle, &sPLChangeTrigger)
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
		return sPLChangeTrigger
	}

	/**
	The channel will not issue a `SPLChange` event until the `dB` value has changed by the amount specified by the `SPLChangeTrigger`.

	*   Setting the `SPLChangeTrigger` to 0 will result in the channel firing events every `DataInterval`. This is useful for applications that implement their own data filtering

	- throws:
	An error or type `PhidgetError`

	- parameters:
		- SPLChangeTrigger: The change trigger value
	*/
	public func setSPLChangeTrigger(_ SPLChangeTrigger: Double) throws {
		let result: PhidgetReturnCode
		result = PhidgetSoundSensor_setSPLChangeTrigger(chandle, SPLChangeTrigger)
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
	}

	/**
	The minimum value that `SPLChangeTrigger` can be set to.

	- returns:
	The change trigger value

	- throws:
	An error or type `PhidgetError`
	*/
	public func getMinSPLChangeTrigger() throws -> Double {
		let result: PhidgetReturnCode
		var minSPLChangeTrigger: Double = 0
		result = PhidgetSoundSensor_getMinSPLChangeTrigger(chandle, &minSPLChangeTrigger)
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
		return minSPLChangeTrigger
	}

	/**
	The maximum value that `SPLChangeTrigger` can be set to.

	- returns:
	The change trigger value

	- throws:
	An error or type `PhidgetError`
	*/
	public func getMaxSPLChangeTrigger() throws -> Double {
		let result: PhidgetReturnCode
		var maxSPLChangeTrigger: Double = 0
		result = PhidgetSoundSensor_getMaxSPLChangeTrigger(chandle, &maxSPLChangeTrigger)
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
		return maxSPLChangeTrigger
	}

	/**
	When selecting a range, first decide how sensitive you want the microphone to be. Select a smaller range when you want more sensitivity from the microphone.

	*   If a `Saturation` event occurrs, increase the range.

	- returns:
	The range value.

	- throws:
	An error or type `PhidgetError`
	*/
	public func getSPLRange() throws -> SPLRange {
		let result: PhidgetReturnCode
		var sPLRange: PhidgetSoundSensor_SPLRange = SPL_RANGE_102dB
		result = PhidgetSoundSensor_getSPLRange(chandle, &sPLRange)
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
		return SPLRange(rawValue: sPLRange.rawValue)!
	}

	/**
	When selecting a range, first decide how sensitive you want the microphone to be. Select a smaller range when you want more sensitivity from the microphone.

	*   If a `Saturation` event occurrs, increase the range.

	- throws:
	An error or type `PhidgetError`

	- parameters:
		- SPLRange: The range value.
	*/
	public func setSPLRange(_ SPLRange: SPLRange) throws {
		let result: PhidgetReturnCode
		result = PhidgetSoundSensor_setSPLRange(chandle, PhidgetSoundSensor_SPLRange(SPLRange.rawValue))
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
	}

	internal override func initializeEvents() {
		initializeBaseEvents()
		PhidgetSoundSensor_setOnSPLChangeHandler(chandle, nativeSPLChangeHandler, UnsafeMutableRawPointer(selfCtx!.toOpaque()))
	}

	internal override func uninitializeEvents() {
		uninitializeBaseEvents()
		PhidgetSoundSensor_setOnSPLChangeHandler(chandle, nil, nil)
	}

	/**
	The most recent SPL values the channel has measured will be reported in this event, which occurs when the `DataInterval` has elapsed.

	*   If a `SPLChangeTrigger` has been set to a non-zero value, the `SPLChange` event will not occur until the `dB` SPL value has changed by at least the `SPLChangeTrigger` value.
	*   The dB SPL value is calculated from the `Octaves` data.
	*   The dBA SPL value is calculated by applying a A-weighted filter to the `Octaves` data.
	*   The dBC SPL value is calculated by applying a C-weighted filter to the `Octaves` data.
	*   The following frequency bands are represented:

	*   octaves\[0\] = 31.5 Hz
	*   octaves\[1\] = 63 Hz
	*   octaves\[2\] = 125 Hz
	*   octaves\[3\] = 250 Hz
	*   octaves\[4\] = 500 Hz
	*   octaves\[5\] = 1 kHz
	*   octaves\[6\] = 2 kHz
	*   octaves\[7\] = 4 kHz
	*   octaves\[8\] = 8 kHz
	*   octaves\[9\] = 16 kHz

	---
	## Parameters:
	*   `dB`: The dB SPL value.
	*   `dBA`: The dBA SPL value.
	*   `dBC`: The dBC SPL value.
	*   `octaves`: The dB SPL value for each band.
	*/
	public let SPLChange = Event<SoundSensor, (dB: Double, dBA: Double, dBC: Double, octaves: [Double])> ()
	let nativeSPLChangeHandler : PhidgetSoundSensor_OnSPLChangeCallback = { ch, ctx, dB, dBA, dBC, octaves in
		let me = Unmanaged<SoundSensor>.fromOpaque(ctx!).takeUnretainedValue()
		me.SPLChange.raise(me, (dB, dBA, dBC, [Double](UnsafeBufferPointer(start: octaves!, count: 10))));
	}

}
