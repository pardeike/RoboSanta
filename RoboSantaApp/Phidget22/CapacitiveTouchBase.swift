import Foundation
//import Phidget22

/**
The Capacitive Touch class gathers input data from capacitive buttons and sliders on Phidget boards.
*/
public class CapacitiveTouchBase : Phidget {

	public init() {
		var h: PhidgetHandle?
		PhidgetCapacitiveTouch_create(&h)
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
			PhidgetCapacitiveTouch_delete(&chandle)
		}
	}

	/**
	The `DataInterval` is the time that must elapse before the channel will fire another `Touch` event.

	*   The data interval is bounded by `MinDataInterval` and `MaxDataInterval`.
	*   The timing between `Touch` events can also be affected by the `TouchValueChangeTrigger`.

	- returns:
	The data interval value

	- throws:
	An error or type `PhidgetError`
	*/
	public func getDataInterval() throws -> UInt32 {
		let result: PhidgetReturnCode
		var dataInterval: UInt32 = 0
		result = PhidgetCapacitiveTouch_getDataInterval(chandle, &dataInterval)
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
		return dataInterval
	}

	/**
	The `DataInterval` is the time that must elapse before the channel will fire another `Touch` event.

	*   The data interval is bounded by `MinDataInterval` and `MaxDataInterval`.
	*   The timing between `Touch` events can also be affected by the `TouchValueChangeTrigger`.

	- throws:
	An error or type `PhidgetError`

	- parameters:
		- dataInterval: The data interval value
	*/
	public func setDataInterval(_ dataInterval: UInt32) throws {
		let result: PhidgetReturnCode
		result = PhidgetCapacitiveTouch_setDataInterval(chandle, dataInterval)
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
	}

	/**
	The minimum value that `DataInterval` can be set to.

	- returns:
	The minimum data interval value

	- throws:
	An error or type `PhidgetError`
	*/
	public func getMinDataInterval() throws -> UInt32 {
		let result: PhidgetReturnCode
		var minDataInterval: UInt32 = 0
		result = PhidgetCapacitiveTouch_getMinDataInterval(chandle, &minDataInterval)
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
		return minDataInterval
	}

	/**
	The maximum value that `DataInterval` can be set to.

	- returns:
	The maximum data interval value

	- throws:
	An error or type `PhidgetError`
	*/
	public func getMaxDataInterval() throws -> UInt32 {
		let result: PhidgetReturnCode
		var maxDataInterval: UInt32 = 0
		result = PhidgetCapacitiveTouch_getMaxDataInterval(chandle, &maxDataInterval)
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
		result = PhidgetCapacitiveTouch_getDataRate(chandle, &dataRate)
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
		result = PhidgetCapacitiveTouch_setDataRate(chandle, dataRate)
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
		result = PhidgetCapacitiveTouch_getMinDataRate(chandle, &minDataRate)
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
		result = PhidgetCapacitiveTouch_getMaxDataRate(chandle, &maxDataRate)
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
		return maxDataRate
	}

	/**
	The most recent touch state that the channel has reported.

	*   This will be 0 or 1

	*   0 is not touched
	*   1 is touched

	- returns:
	The touched state

	- throws:
	An error or type `PhidgetError`
	*/
	public func getIsTouched() throws -> Bool {
		let result: PhidgetReturnCode
		var isTouched: Int32 = 0
		result = PhidgetCapacitiveTouch_getIsTouched(chandle, &isTouched)
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
		return (isTouched == 0 ? false : true)
	}

	/**
	Determines the sensitivity of all capacitive regions on the device.

	*   Higher values result in greater touch sensitivity.
	*   The sensitivity value is bounded by `MinSensitivity` and `MaxSensitivity`.

	- returns:
	The sensitivity value

	- throws:
	An error or type `PhidgetError`
	*/
	public func getSensitivity() throws -> Double {
		let result: PhidgetReturnCode
		var sensitivity: Double = 0
		result = PhidgetCapacitiveTouch_getSensitivity(chandle, &sensitivity)
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
		return sensitivity
	}

	/**
	Determines the sensitivity of all capacitive regions on the device.

	*   Higher values result in greater touch sensitivity.
	*   The sensitivity value is bounded by `MinSensitivity` and `MaxSensitivity`.

	- throws:
	An error or type `PhidgetError`

	- parameters:
		- sensitivity: The sensitivity value
	*/
	public func setSensitivity(_ sensitivity: Double) throws {
		let result: PhidgetReturnCode
		result = PhidgetCapacitiveTouch_setSensitivity(chandle, sensitivity)
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
	}

	/**
	The minimum value that `Sensitivity` can be set to.

	- returns:
	The minimum sensitivity value

	- throws:
	An error or type `PhidgetError`
	*/
	public func getMinSensitivity() throws -> Double {
		let result: PhidgetReturnCode
		var minSensitivity: Double = 0
		result = PhidgetCapacitiveTouch_getMinSensitivity(chandle, &minSensitivity)
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
		return minSensitivity
	}

	/**
	The maximum value that `Sensitivity` can be set to.

	- returns:
	The maximum sensitivity value

	- throws:
	An error or type `PhidgetError`
	*/
	public func getMaxSensitivity() throws -> Double {
		let result: PhidgetReturnCode
		var maxSensitivity: Double = 0
		result = PhidgetCapacitiveTouch_getMaxSensitivity(chandle, &maxSensitivity)
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
		return maxSensitivity
	}

	/**
	The most recent touch value that the channel has reported.

	*   This will be 0 or 1 for button-type inputs, or a ratio between 0-1 for axis-type inputs.
	*   This value is bounded by `MinTouchValue` and `MaxTouchValue`
	*   The value is not reset when the touch ends

	- returns:
	The touch input value

	- throws:
	An error or type `PhidgetError`
	*/
	public func getTouchValue() throws -> Double {
		let result: PhidgetReturnCode
		var touchValue: Double = 0
		result = PhidgetCapacitiveTouch_getTouchValue(chandle, &touchValue)
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
		return touchValue
	}

	/**
	The minimum value the `Touch` event will report.

	- returns:
	The minimum touch input value

	- throws:
	An error or type `PhidgetError`
	*/
	public func getMinTouchValue() throws -> Double {
		let result: PhidgetReturnCode
		var minTouchValue: Double = 0
		result = PhidgetCapacitiveTouch_getMinTouchValue(chandle, &minTouchValue)
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
		return minTouchValue
	}

	/**
	The maximum value the `Touch` event will report.

	- returns:
	The maximum touch input value

	- throws:
	An error or type `PhidgetError`
	*/
	public func getMaxTouchValue() throws -> Double {
		let result: PhidgetReturnCode
		var maxTouchValue: Double = 0
		result = PhidgetCapacitiveTouch_getMaxTouchValue(chandle, &maxTouchValue)
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
		return maxTouchValue
	}

	/**
	The channel will not issue a `Touch` event until the touch value has changed by the amount specified by the `TouchValueChangeTrigger`.

	*   Setting the `TouchValueChangeTrigger` to 0 will result in the channel firing events every `DataInterval`. This is useful for applications that implement their own data filtering

	- returns:
	The change trigger value

	- throws:
	An error or type `PhidgetError`
	*/
	public func getTouchValueChangeTrigger() throws -> Double {
		let result: PhidgetReturnCode
		var touchValueChangeTrigger: Double = 0
		result = PhidgetCapacitiveTouch_getTouchValueChangeTrigger(chandle, &touchValueChangeTrigger)
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
		return touchValueChangeTrigger
	}

	/**
	The channel will not issue a `Touch` event until the touch value has changed by the amount specified by the `TouchValueChangeTrigger`.

	*   Setting the `TouchValueChangeTrigger` to 0 will result in the channel firing events every `DataInterval`. This is useful for applications that implement their own data filtering

	- throws:
	An error or type `PhidgetError`

	- parameters:
		- touchValueChangeTrigger: The change trigger value
	*/
	public func setTouchValueChangeTrigger(_ touchValueChangeTrigger: Double) throws {
		let result: PhidgetReturnCode
		result = PhidgetCapacitiveTouch_setTouchValueChangeTrigger(chandle, touchValueChangeTrigger)
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
	}

	/**
	The minimum value that `TouchValueChangeTrigger` can be set to.

	- returns:
	The minimum change trigger value

	- throws:
	An error or type `PhidgetError`
	*/
	public func getMinTouchValueChangeTrigger() throws -> Double {
		let result: PhidgetReturnCode
		var minTouchValueChangeTrigger: Double = 0
		result = PhidgetCapacitiveTouch_getMinTouchValueChangeTrigger(chandle, &minTouchValueChangeTrigger)
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
		return minTouchValueChangeTrigger
	}

	/**
	The maximum value that `TouchValueChangeTrigger` can be set to.

	- returns:
	The maximum change trigger value

	- throws:
	An error or type `PhidgetError`
	*/
	public func getMaxTouchValueChangeTrigger() throws -> Double {
		let result: PhidgetReturnCode
		var maxTouchValueChangeTrigger: Double = 0
		result = PhidgetCapacitiveTouch_getMaxTouchValueChangeTrigger(chandle, &maxTouchValueChangeTrigger)
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
		return maxTouchValueChangeTrigger
	}

	internal override func initializeEvents() {
		initializeBaseEvents()
		PhidgetCapacitiveTouch_setOnTouchHandler(chandle, nativeTouchHandler, UnsafeMutableRawPointer(selfCtx!.toOpaque()))
		PhidgetCapacitiveTouch_setOnTouchEndHandler(chandle, nativeTouchEndHandler, UnsafeMutableRawPointer(selfCtx!.toOpaque()))
	}

	internal override func uninitializeEvents() {
		uninitializeBaseEvents()
		PhidgetCapacitiveTouch_setOnTouchHandler(chandle, nil, nil)
		PhidgetCapacitiveTouch_setOnTouchEndHandler(chandle, nil, nil)
	}

	/**
	The most recent touch value the channel has measured will be reported in this event, which occurs when the `DataInterval` has elapsed.

	*   If a `TouchValueChangeTrigger` has been set to a non-zero value, the `Touch` event will not occur until the touch value has changed by at least the `TouchValueChangeTrigger` value.

	---
	## Parameters:
	*   `touchValue`: Value of the touch input axis.
	*/
	public let touch = Event<CapacitiveTouch, Double> ()
	let nativeTouchHandler : PhidgetCapacitiveTouch_OnTouchCallback = { ch, ctx, touchValue in
		let me = Unmanaged<CapacitiveTouch>.fromOpaque(ctx!).takeUnretainedValue()
		me.touch.raise(me, touchValue);
	}

	/**
	The channel will report a `TouchEnd` event to signify that it is no longer detecting a touch.
	*/
	public let touchEnd = SimpleEvent<CapacitiveTouch> ()
	let nativeTouchEndHandler : PhidgetCapacitiveTouch_OnTouchEndCallback = { ch, ctx in
		let me = Unmanaged<CapacitiveTouch>.fromOpaque(ctx!).takeUnretainedValue()
		me.touchEnd.raise(me);
	}

}
