import Foundation
//import Phidget22

/**
The Encoder class is used to read position data from quadrature encoders in order to track linear or rotary movement. If the device supports an index pin as a reference point, you can also access it through this class.
*/
public class EncoderBase : Phidget {

	public init() {
		var h: PhidgetHandle?
		PhidgetEncoder_create(&h)
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
			PhidgetEncoder_delete(&chandle)
		}
	}

	/**
	The `DataInterval` is the time that must elapse before the channel will fire another `PositionChange` event.

	*   The data interval is bounded by `MinDataInterval` and `MaxDataInterval`.
	*   The timing between `PositionChange` events can also be affected by the `PositionChangeTrigger`.

	- returns:
	The data interval value

	- throws:
	An error or type `PhidgetError`
	*/
	public func getDataInterval() throws -> UInt32 {
		let result: PhidgetReturnCode
		var dataInterval: UInt32 = 0
		result = PhidgetEncoder_getDataInterval(chandle, &dataInterval)
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
		return dataInterval
	}

	/**
	The `DataInterval` is the time that must elapse before the channel will fire another `PositionChange` event.

	*   The data interval is bounded by `MinDataInterval` and `MaxDataInterval`.
	*   The timing between `PositionChange` events can also be affected by the `PositionChangeTrigger`.

	- throws:
	An error or type `PhidgetError`

	- parameters:
		- dataInterval: The data interval value
	*/
	public func setDataInterval(_ dataInterval: UInt32) throws {
		let result: PhidgetReturnCode
		result = PhidgetEncoder_setDataInterval(chandle, dataInterval)
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
		result = PhidgetEncoder_getMinDataInterval(chandle, &minDataInterval)
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
		result = PhidgetEncoder_getMaxDataInterval(chandle, &maxDataInterval)
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
		result = PhidgetEncoder_getDataRate(chandle, &dataRate)
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
		result = PhidgetEncoder_setDataRate(chandle, dataRate)
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
		result = PhidgetEncoder_getMinDataRate(chandle, &minDataRate)
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
		result = PhidgetEncoder_getMaxDataRate(chandle, &maxDataRate)
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
		return maxDataRate
	}

	/**
	The enabled state of the encoder.

	- returns:
	The enabled value

	- throws:
	An error or type `PhidgetError`
	*/
	public func getEnabled() throws -> Bool {
		let result: PhidgetReturnCode
		var enabled: Int32 = 0
		result = PhidgetEncoder_getEnabled(chandle, &enabled)
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
		return (enabled == 0 ? false : true)
	}

	/**
	The enabled state of the encoder.

	- throws:
	An error or type `PhidgetError`

	- parameters:
		- enabled: The enabled value
	*/
	public func setEnabled(_ enabled: Bool) throws {
		let result: PhidgetReturnCode
		result = PhidgetEncoder_setEnabled(chandle, (enabled ? 1 : 0))
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
	}

	/**
	The most recent position of the index channel calculated by the Phidgets library.

	*   The index channel will usually pulse once per rotation.
	*   Setting the encoder position will move the index position the same amount so their relative position stays the same.
	*   Index position is tracked locally as the last position at which the index was triggered. Setting position will only affect the local copy of the index position value. This means that index positions seen by multiple network applications may not agree.

	- returns:
	The index position value

	- throws:
	An error or type `PhidgetError`
	*/
	public func getIndexPosition() throws -> Int64 {
		let result: PhidgetReturnCode
		var indexPosition: Int64 = 0
		result = PhidgetEncoder_getIndexPosition(chandle, &indexPosition)
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
		return indexPosition
	}

	/**
	The encoder interface mode. Match the mode to the type of encoder you have attached.

	*   It is recommended to only change this when the encoder disabled in order to avoid unexpected results.

	- returns:
	The IO mode value.

	- throws:
	An error or type `PhidgetError`
	*/
	public func getIOMode() throws -> EncoderIOMode {
		let result: PhidgetReturnCode
		var iOMode: Phidget_EncoderIOMode = ENCODER_IO_MODE_PUSH_PULL
		result = PhidgetEncoder_getIOMode(chandle, &iOMode)
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
		return EncoderIOMode(rawValue: iOMode.rawValue)!
	}

	/**
	The encoder interface mode. Match the mode to the type of encoder you have attached.

	*   It is recommended to only change this when the encoder disabled in order to avoid unexpected results.

	- throws:
	An error or type `PhidgetError`

	- parameters:
		- IOMode: The IO mode value.
	*/
	public func setIOMode(_ IOMode: EncoderIOMode) throws {
		let result: PhidgetReturnCode
		result = PhidgetEncoder_setIOMode(chandle, Phidget_EncoderIOMode(IOMode.rawValue))
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
	}

	/**
	The most recent position value calculated by the Phidgets library.

	*   Position counts quadrature edges within a quadrature cycle. This means there are four counts per full quadrature cycle.
	*   Position is tracked locally as the total position change from the time the channel is opened. Setting position will only affect the local copy of the position value. This means that positions seen by multiple network applications may not agree.

	- returns:
	The position value

	- throws:
	An error or type `PhidgetError`
	*/
	public func getPosition() throws -> Int64 {
		let result: PhidgetReturnCode
		var position: Int64 = 0
		result = PhidgetEncoder_getPosition(chandle, &position)
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
		return position
	}

	/**
	The most recent position value calculated by the Phidgets library.

	*   Position counts quadrature edges within a quadrature cycle. This means there are four counts per full quadrature cycle.
	*   Position is tracked locally as the total position change from the time the channel is opened. Setting position will only affect the local copy of the position value. This means that positions seen by multiple network applications may not agree.

	- throws:
	An error or type `PhidgetError`

	- parameters:
		- position: The position value
	*/
	public func setPosition(_ position: Int64) throws {
		let result: PhidgetReturnCode
		result = PhidgetEncoder_setPosition(chandle, position)
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
	}

	/**
	The channel will not issue a `PositionChange` event until the position value has changed by the amount specified by the `PositionChangeTrigger`.

	*   Setting the `PositionChangeTrigger` to 0 will result in the channel firing events every `DataInterval`. This is useful for applications that implement their own data filtering

	- returns:
	The change trigger value

	- throws:
	An error or type `PhidgetError`
	*/
	public func getPositionChangeTrigger() throws -> UInt32 {
		let result: PhidgetReturnCode
		var positionChangeTrigger: UInt32 = 0
		result = PhidgetEncoder_getPositionChangeTrigger(chandle, &positionChangeTrigger)
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
		return positionChangeTrigger
	}

	/**
	The channel will not issue a `PositionChange` event until the position value has changed by the amount specified by the `PositionChangeTrigger`.

	*   Setting the `PositionChangeTrigger` to 0 will result in the channel firing events every `DataInterval`. This is useful for applications that implement their own data filtering

	- throws:
	An error or type `PhidgetError`

	- parameters:
		- positionChangeTrigger: The change trigger value
	*/
	public func setPositionChangeTrigger(_ positionChangeTrigger: UInt32) throws {
		let result: PhidgetReturnCode
		result = PhidgetEncoder_setPositionChangeTrigger(chandle, positionChangeTrigger)
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
	}

	/**
	The minimum value that `PositionChangeTrigger` can be set to.

	- returns:
	The change trigger value

	- throws:
	An error or type `PhidgetError`
	*/
	public func getMinPositionChangeTrigger() throws -> UInt32 {
		let result: PhidgetReturnCode
		var minPositionChangeTrigger: UInt32 = 0
		result = PhidgetEncoder_getMinPositionChangeTrigger(chandle, &minPositionChangeTrigger)
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
		return minPositionChangeTrigger
	}

	/**
	The maximum value that `PositionChangeTrigger` can be set to.

	- returns:
	The change trigger value

	- throws:
	An error or type `PhidgetError`
	*/
	public func getMaxPositionChangeTrigger() throws -> UInt32 {
		let result: PhidgetReturnCode
		var maxPositionChangeTrigger: UInt32 = 0
		result = PhidgetEncoder_getMaxPositionChangeTrigger(chandle, &maxPositionChangeTrigger)
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
		return maxPositionChangeTrigger
	}

	internal override func initializeEvents() {
		initializeBaseEvents()
		PhidgetEncoder_setOnPositionChangeHandler(chandle, nativePositionChangeHandler, UnsafeMutableRawPointer(selfCtx!.toOpaque()))
	}

	internal override func uninitializeEvents() {
		uninitializeBaseEvents()
		PhidgetEncoder_setOnPositionChangeHandler(chandle, nil, nil)
	}

	/**
	The most recent position change and time change the channel has measured will be reported in this event, which occurs when the `DataInterval` has elapsed.

	*   If a `PositionChangeTrigger` has been set to a non-zero value, the `PositionChange` event will not occur until the position has changed by at least the `PositionChangeTrigger` value.

	---
	## Parameters:
	*   `positionChange`: The amount the position changed since the last change event
	*   `timeChange`: The time elapsed since the last change event in milliseconds
	*   `indexTriggered`: True if the index was passed since the last change event
	*/
	public let positionChange = Event<Encoder, (positionChange: Int, timeChange: Double, indexTriggered: Bool)> ()
	let nativePositionChangeHandler : PhidgetEncoder_OnPositionChangeCallback = { ch, ctx, positionChange, timeChange, indexTriggered in
		let me = Unmanaged<Encoder>.fromOpaque(ctx!).takeUnretainedValue()
		me.positionChange.raise(me, (Int(positionChange), timeChange, (indexTriggered == 0 ? false : true)));
	}

}
