import Foundation
//import Phidget22

/**
The Distance Sensor class gathers data from the distance sensor on a Phidget board.

If you're using a simple 0-5V sensor that does not have its own firmware, use the VoltageInput or VoltageRatioInput class instead, as specified for your device.
*/
public class DistanceSensorBase : Phidget {

	public init() {
		var h: PhidgetHandle?
		PhidgetDistanceSensor_create(&h)
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
			PhidgetDistanceSensor_delete(&chandle)
		}
	}

	/**
	The `DataInterval` is the time that must elapse before the channel will fire another event.

	*   The data interval is bounded by `MinDataInterval` and `MaxDataInterval`.
	*   The timing between events can also be affected by the `DistanceChangeTrigger`.

	- returns:
	The data interval value

	- throws:
	An error or type `PhidgetError`
	*/
	public func getDataInterval() throws -> UInt32 {
		let result: PhidgetReturnCode
		var dataInterval: UInt32 = 0
		result = PhidgetDistanceSensor_getDataInterval(chandle, &dataInterval)
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
		return dataInterval
	}

	/**
	The `DataInterval` is the time that must elapse before the channel will fire another event.

	*   The data interval is bounded by `MinDataInterval` and `MaxDataInterval`.
	*   The timing between events can also be affected by the `DistanceChangeTrigger`.

	- throws:
	An error or type `PhidgetError`

	- parameters:
		- dataInterval: The data interval value
	*/
	public func setDataInterval(_ dataInterval: UInt32) throws {
		let result: PhidgetReturnCode
		result = PhidgetDistanceSensor_setDataInterval(chandle, dataInterval)
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
		result = PhidgetDistanceSensor_getMinDataInterval(chandle, &minDataInterval)
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
		result = PhidgetDistanceSensor_getMaxDataInterval(chandle, &maxDataInterval)
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
		result = PhidgetDistanceSensor_getDataRate(chandle, &dataRate)
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
		result = PhidgetDistanceSensor_setDataRate(chandle, dataRate)
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
		result = PhidgetDistanceSensor_getMinDataRate(chandle, &minDataRate)
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
		result = PhidgetDistanceSensor_getMaxDataRate(chandle, &maxDataRate)
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
		return maxDataRate
	}

	/**
	The most recent distance value that the channel has reported.

	*   This value will always be between `MinDistance` and `MaxDistance`.

	- returns:
	The distance value

	- throws:
	An error or type `PhidgetError`
	*/
	public func getDistance() throws -> UInt32 {
		let result: PhidgetReturnCode
		var distance: UInt32 = 0
		result = PhidgetDistanceSensor_getDistance(chandle, &distance)
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
		return distance
	}

	/**
	The minimum distance that a event will report.

	- returns:
	The distance value

	- throws:
	An error or type `PhidgetError`
	*/
	public func getMinDistance() throws -> UInt32 {
		let result: PhidgetReturnCode
		var minDistance: UInt32 = 0
		result = PhidgetDistanceSensor_getMinDistance(chandle, &minDistance)
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
		return minDistance
	}

	/**
	The maximum distance that a event will report.

	- returns:
	The distance value

	- throws:
	An error or type `PhidgetError`
	*/
	public func getMaxDistance() throws -> UInt32 {
		let result: PhidgetReturnCode
		var maxDistance: UInt32 = 0
		result = PhidgetDistanceSensor_getMaxDistance(chandle, &maxDistance)
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
		return maxDistance
	}

	/**
	The channel will not issue an event until the distance value has changed by the amount specified by the `DistanceChangeTrigger`.

	*   Setting the `DistanceChangeTrigger` to 0 will result in the channel firing events every `DataInterval`. This is useful for applications that implement their own data filtering,

	- returns:
	The change trigger value

	- throws:
	An error or type `PhidgetError`
	*/
	public func getDistanceChangeTrigger() throws -> UInt32 {
		let result: PhidgetReturnCode
		var distanceChangeTrigger: UInt32 = 0
		result = PhidgetDistanceSensor_getDistanceChangeTrigger(chandle, &distanceChangeTrigger)
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
		return distanceChangeTrigger
	}

	/**
	The channel will not issue an event until the distance value has changed by the amount specified by the `DistanceChangeTrigger`.

	*   Setting the `DistanceChangeTrigger` to 0 will result in the channel firing events every `DataInterval`. This is useful for applications that implement their own data filtering,

	- throws:
	An error or type `PhidgetError`

	- parameters:
		- distanceChangeTrigger: The change trigger value
	*/
	public func setDistanceChangeTrigger(_ distanceChangeTrigger: UInt32) throws {
		let result: PhidgetReturnCode
		result = PhidgetDistanceSensor_setDistanceChangeTrigger(chandle, distanceChangeTrigger)
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
	}

	/**
	The minimum value that `DistanceChangeTrigger` can be set to.

	- returns:
	The change trigger value

	- throws:
	An error or type `PhidgetError`
	*/
	public func getMinDistanceChangeTrigger() throws -> UInt32 {
		let result: PhidgetReturnCode
		var minDistanceChangeTrigger: UInt32 = 0
		result = PhidgetDistanceSensor_getMinDistanceChangeTrigger(chandle, &minDistanceChangeTrigger)
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
		return minDistanceChangeTrigger
	}

	/**
	The maximum value that `DistanceChangeTrigger` can be set to.

	- returns:
	The change trigger value

	- throws:
	An error or type `PhidgetError`
	*/
	public func getMaxDistanceChangeTrigger() throws -> UInt32 {
		let result: PhidgetReturnCode
		var maxDistanceChangeTrigger: UInt32 = 0
		result = PhidgetDistanceSensor_getMaxDistanceChangeTrigger(chandle, &maxDistanceChangeTrigger)
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
		return maxDistanceChangeTrigger
	}

	/**
	When set to true, the device will operate more quietly.

	*   The measurable range is reduced when operating in quiet mode.

	- returns:
	The quiet mode value

	- throws:
	An error or type `PhidgetError`
	*/
	public func getSonarQuietMode() throws -> Bool {
		let result: PhidgetReturnCode
		var sonarQuietMode: Int32 = 0
		result = PhidgetDistanceSensor_getSonarQuietMode(chandle, &sonarQuietMode)
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
		return (sonarQuietMode == 0 ? false : true)
	}

	/**
	When set to true, the device will operate more quietly.

	*   The measurable range is reduced when operating in quiet mode.

	- throws:
	An error or type `PhidgetError`

	- parameters:
		- sonarQuietMode: The quiet mode value
	*/
	public func setSonarQuietMode(_ sonarQuietMode: Bool) throws {
		let result: PhidgetReturnCode
		result = PhidgetDistanceSensor_setSonarQuietMode(chandle, (sonarQuietMode ? 1 : 0))
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
	}

	/**
	The most recent reflection values that the channel has reported.

	*   The distance values will always be between `MinDistance` and `MaxDistance`.
	*   The closest reflection will be placed at index 0 of the distances array, and the furthest reflection at index 7
	*   The amplitude values are relative amplitudes of the reflections that are normalized to an arbitrary scale.

	- returns:
		- distances: The reflection values
		- amplitudes: The amplitude values
		- count: The number of reflections

	- throws:
	An error or type `PhidgetError`
	*/
	public func getSonarReflections() throws -> (distances: [UInt32], amplitudes: [UInt32], count: UInt32) {
		let result: PhidgetReturnCode
		var distances: (UInt32, UInt32, UInt32, UInt32, UInt32, UInt32, UInt32, UInt32) = (0, 0, 0, 0, 0, 0, 0, 0)
		var amplitudes: (UInt32, UInt32, UInt32, UInt32, UInt32, UInt32, UInt32, UInt32) = (0, 0, 0, 0, 0, 0, 0, 0)
		var count: UInt32 = 0
		result = PhidgetDistanceSensor_getSonarReflections(chandle, &distances, &amplitudes, &count)
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
		return (distances: [distances.0, distances.1, distances.2, distances.3, distances.4, distances.5, distances.6, distances.7], amplitudes: [amplitudes.0, amplitudes.1, amplitudes.2, amplitudes.3, amplitudes.4, amplitudes.5, amplitudes.6, amplitudes.7], count: count)
	}

	internal override func initializeEvents() {
		initializeBaseEvents()
		PhidgetDistanceSensor_setOnDistanceChangeHandler(chandle, nativeDistanceChangeHandler, UnsafeMutableRawPointer(selfCtx!.toOpaque()))
		PhidgetDistanceSensor_setOnSonarReflectionsUpdateHandler(chandle, nativeSonarReflectionsUpdateHandler, UnsafeMutableRawPointer(selfCtx!.toOpaque()))
	}

	internal override func uninitializeEvents() {
		uninitializeBaseEvents()
		PhidgetDistanceSensor_setOnDistanceChangeHandler(chandle, nil, nil)
		PhidgetDistanceSensor_setOnSonarReflectionsUpdateHandler(chandle, nil, nil)
	}

	/**
	The most recent distance value the channel has measured will be reported in this event, which occurs when the `DataInterval` has elapsed.

	*   If a `DistanceChangeTrigger` has been set to a non-zero value, the `DistanceChange` event will not occur until the distance has changed by at least the `DistanceChangeTrigger` value.

	---
	## Parameters:
	*   `distance`: The current distance
	*/
	public let distanceChange = Event<DistanceSensor, UInt32> ()
	let nativeDistanceChangeHandler : PhidgetDistanceSensor_OnDistanceChangeCallback = { ch, ctx, distance in
		let me = Unmanaged<DistanceSensor>.fromOpaque(ctx!).takeUnretainedValue()
		me.distanceChange.raise(me, distance);
	}

	/**
	The most recent reflections the channel has detected will be reported in this event, which occurs when the `DataInterval` has elapsed.

	*   If a `DistanceChangeTrigger` has been set to a non-zero value, the `SonarReflectionsUpdate` event will not occur until the distance has changed by at least the `DistanceChangeTrigger` value.
	*   The closest reflection will be placed at index 0 of the _distances_ array, and the furthest reflection at index 7.
	*   If you are only interested in the closest reflection, you can simply use the `DistanceChange` event.
	*   The values reported as amplitudes are relative amplitudes of the reflections that are normalized to an arbitrary scale.

	---
	## Parameters:
	*   `distances`: The reflection values
	*   `amplitudes`: The amplitude values
	*   `count`: The number of reflections detected
	*/
	public let sonarReflectionsUpdate = Event<DistanceSensor, (distances: [UInt32], amplitudes: [UInt32], count: UInt32)> ()
	let nativeSonarReflectionsUpdateHandler : PhidgetDistanceSensor_OnSonarReflectionsUpdateCallback = { ch, ctx, distances, amplitudes, count in
		let me = Unmanaged<DistanceSensor>.fromOpaque(ctx!).takeUnretainedValue()
		me.sonarReflectionsUpdate.raise(me, ([UInt32](UnsafeBufferPointer(start: distances!, count: 8)), [UInt32](UnsafeBufferPointer(start: amplitudes!, count: 8)), count));
	}

}
