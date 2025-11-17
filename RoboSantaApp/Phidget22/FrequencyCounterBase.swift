import Foundation
//import Phidget22

/**
The Frequency Counter class is used to measure the frequency of pulses in an electronic signal, or to count the pulses in the signal. Such signals can come from other electronics, or certain sensors that have a pulse output.
*/
public class FrequencyCounterBase : Phidget {

	public init() {
		var h: PhidgetHandle?
		PhidgetFrequencyCounter_create(&h)
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
			PhidgetFrequencyCounter_delete(&chandle)
		}
	}

	/**
	The most recent count value the channel has reported.

	*   The count represents the total number of pulses since the the channel was opened, or last reset.

	- returns:
	The count value

	- throws:
	An error or type `PhidgetError`
	*/
	public func getCount() throws -> UInt64 {
		let result: PhidgetReturnCode
		var count: UInt64 = 0
		result = PhidgetFrequencyCounter_getCount(chandle, &count)
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
		return count
	}

	/**
	The `DataInterval` is the time that must elapse before the channel will fire another `CountChange` / `FrequencyChange` event.

	*   The data interval is bounded by `MinDataInterval` and `MaxDataInterval`.

	- returns:
	The data interval value

	- throws:
	An error or type `PhidgetError`
	*/
	public func getDataInterval() throws -> UInt32 {
		let result: PhidgetReturnCode
		var dataInterval: UInt32 = 0
		result = PhidgetFrequencyCounter_getDataInterval(chandle, &dataInterval)
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
		return dataInterval
	}

	/**
	The `DataInterval` is the time that must elapse before the channel will fire another `CountChange` / `FrequencyChange` event.

	*   The data interval is bounded by `MinDataInterval` and `MaxDataInterval`.

	- throws:
	An error or type `PhidgetError`

	- parameters:
		- dataInterval: The data interval value
	*/
	public func setDataInterval(_ dataInterval: UInt32) throws {
		let result: PhidgetReturnCode
		result = PhidgetFrequencyCounter_setDataInterval(chandle, dataInterval)
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
		result = PhidgetFrequencyCounter_getMinDataInterval(chandle, &minDataInterval)
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
		result = PhidgetFrequencyCounter_getMaxDataInterval(chandle, &maxDataInterval)
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
		result = PhidgetFrequencyCounter_getDataRate(chandle, &dataRate)
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
		result = PhidgetFrequencyCounter_setDataRate(chandle, dataRate)
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
		result = PhidgetFrequencyCounter_getMinDataRate(chandle, &minDataRate)
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
		result = PhidgetFrequencyCounter_getMaxDataRate(chandle, &maxDataRate)
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
		return maxDataRate
	}

	/**
	Enables or disables the channel.

	*   When a channel is disabled, it will not longer register counts, therefore the `TimeElapsed` and `Count` will not be updated until the channel is re-enabled.

	- returns:
	The enabled value

	- throws:
	An error or type `PhidgetError`
	*/
	public func getEnabled() throws -> Bool {
		let result: PhidgetReturnCode
		var enabled: Int32 = 0
		result = PhidgetFrequencyCounter_getEnabled(chandle, &enabled)
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
		return (enabled == 0 ? false : true)
	}

	/**
	Enables or disables the channel.

	*   When a channel is disabled, it will not longer register counts, therefore the `TimeElapsed` and `Count` will not be updated until the channel is re-enabled.

	- throws:
	An error or type `PhidgetError`

	- parameters:
		- enabled: The enabled value
	*/
	public func setEnabled(_ enabled: Bool) throws {
		let result: PhidgetReturnCode
		result = PhidgetFrequencyCounter_setEnabled(chandle, (enabled ? 1 : 0))
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
	}

	/**
	Determines the signal type that the channel responds to.

	*   The filter type is chosen based on the type of input signal. See the `FrequencyFilterType` entry under Enumerations for more information.

	- returns:
	The filter value

	- throws:
	An error or type `PhidgetError`
	*/
	public func getFilterType() throws -> FrequencyFilterType {
		let result: PhidgetReturnCode
		var filterType: PhidgetFrequencyCounter_FilterType = FILTER_TYPE_ZERO_CROSSING
		result = PhidgetFrequencyCounter_getFilterType(chandle, &filterType)
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
		return FrequencyFilterType(rawValue: filterType.rawValue)!
	}

	/**
	Determines the signal type that the channel responds to.

	*   The filter type is chosen based on the type of input signal. See the `FrequencyFilterType` entry under Enumerations for more information.

	- throws:
	An error or type `PhidgetError`

	- parameters:
		- filterType: The filter value
	*/
	public func setFilterType(_ filterType: FrequencyFilterType) throws {
		let result: PhidgetReturnCode
		result = PhidgetFrequencyCounter_setFilterType(chandle, PhidgetFrequencyCounter_FilterType(filterType.rawValue))
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
	}

	/**
	The most recent frequency value that the channel has reported.

	*   This value will always be between 0 Hz and `MaxFrequency`.

	- returns:
	The frequency value

	- throws:
	An error or type `PhidgetError`
	*/
	public func getFrequency() throws -> Double {
		let result: PhidgetReturnCode
		var frequency: Double = 0
		result = PhidgetFrequencyCounter_getFrequency(chandle, &frequency)
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
		return frequency
	}

	/**
	The maximum value the `FrequencyChange` event will report.

	- returns:
	The frequency value

	- throws:
	An error or type `PhidgetError`
	*/
	public func getMaxFrequency() throws -> Double {
		let result: PhidgetReturnCode
		var maxFrequency: Double = 0
		result = PhidgetFrequencyCounter_getMaxFrequency(chandle, &maxFrequency)
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
		return maxFrequency
	}

	/**
	The frequency at which zero hertz is assumed.

	*   This means any frequency at or below the `FrequencyCutoff` value will be reported as 0 Hz.
	*   This property is stored locally, so other users who have this Phidget open over a network connection won't see the effects of your selected cutoff.

	- returns:
	The frequency cutoff value

	- throws:
	An error or type `PhidgetError`
	*/
	public func getFrequencyCutoff() throws -> Double {
		let result: PhidgetReturnCode
		var frequencyCutoff: Double = 0
		result = PhidgetFrequencyCounter_getFrequencyCutoff(chandle, &frequencyCutoff)
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
		return frequencyCutoff
	}

	/**
	The frequency at which zero hertz is assumed.

	*   This means any frequency at or below the `FrequencyCutoff` value will be reported as 0 Hz.
	*   This property is stored locally, so other users who have this Phidget open over a network connection won't see the effects of your selected cutoff.

	- throws:
	An error or type `PhidgetError`

	- parameters:
		- frequencyCutoff: The frequency cutoff value
	*/
	public func setFrequencyCutoff(_ frequencyCutoff: Double) throws {
		let result: PhidgetReturnCode
		result = PhidgetFrequencyCounter_setFrequencyCutoff(chandle, frequencyCutoff)
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
	}

	/**
	The minimum value that `FrequencyCutoff` can be set to.

	- returns:
	The frequency value

	- throws:
	An error or type `PhidgetError`
	*/
	public func getMinFrequencyCutoff() throws -> Double {
		let result: PhidgetReturnCode
		var minFrequencyCutoff: Double = 0
		result = PhidgetFrequencyCounter_getMinFrequencyCutoff(chandle, &minFrequencyCutoff)
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
		return minFrequencyCutoff
	}

	/**
	The maximum value that `FrequencyCutoff` can be set to.

	- returns:
	The frequency value

	- throws:
	An error or type `PhidgetError`
	*/
	public func getMaxFrequencyCutoff() throws -> Double {
		let result: PhidgetReturnCode
		var maxFrequencyCutoff: Double = 0
		result = PhidgetFrequencyCounter_getMaxFrequencyCutoff(chandle, &maxFrequencyCutoff)
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
		return maxFrequencyCutoff
	}

	/**
	The input polarity mode for your channel.

	*   See your device's User Guide for more information about what value to chooose for the `InputMode`

	- returns:
	The input mode value

	- throws:
	An error or type `PhidgetError`
	*/
	public func getInputMode() throws -> InputMode {
		let result: PhidgetReturnCode
		var inputMode: Phidget_InputMode = INPUT_MODE_NPN
		result = PhidgetFrequencyCounter_getInputMode(chandle, &inputMode)
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
		return InputMode(rawValue: inputMode.rawValue)!
	}

	/**
	The input polarity mode for your channel.

	*   See your device's User Guide for more information about what value to chooose for the `InputMode`

	- throws:
	An error or type `PhidgetError`

	- parameters:
		- inputMode: The input mode value
	*/
	public func setInputMode(_ inputMode: InputMode) throws {
		let result: PhidgetReturnCode
		result = PhidgetFrequencyCounter_setInputMode(chandle, Phidget_InputMode(inputMode.rawValue))
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
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
		result = PhidgetFrequencyCounter_getPowerSupply(chandle, &powerSupply)
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
		result = PhidgetFrequencyCounter_setPowerSupply(chandle, Phidget_PowerSupply(powerSupply.rawValue))
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
	}

	/**
	Resets the `Count` and `TimeElapsed`.

	*   For best results, reset should be called when the channel is disabled.

	- throws:
	An error or type `PhidgetError`
	*/
	public func reset() throws {
		let result: PhidgetReturnCode
		result = PhidgetFrequencyCounter_reset(chandle)
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
	}

	/**
	The amount of time the frequency counter has been enabled for.

	*   This property complements `Count`, the total number of pulses detected since the channel was opened, or last reset.

	- returns:
	The time value

	- throws:
	An error or type `PhidgetError`
	*/
	public func getTimeElapsed() throws -> Double {
		let result: PhidgetReturnCode
		var timeElapsed: Double = 0
		result = PhidgetFrequencyCounter_getTimeElapsed(chandle, &timeElapsed)
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
		return timeElapsed
	}

	internal override func initializeEvents() {
		initializeBaseEvents()
		PhidgetFrequencyCounter_setOnCountChangeHandler(chandle, nativeCountChangeHandler, UnsafeMutableRawPointer(selfCtx!.toOpaque()))
		PhidgetFrequencyCounter_setOnFrequencyChangeHandler(chandle, nativeFrequencyChangeHandler, UnsafeMutableRawPointer(selfCtx!.toOpaque()))
	}

	internal override func uninitializeEvents() {
		uninitializeBaseEvents()
		PhidgetFrequencyCounter_setOnCountChangeHandler(chandle, nil, nil)
		PhidgetFrequencyCounter_setOnFrequencyChangeHandler(chandle, nil, nil)
	}

	/**
	The most recent values the channel has measured will be reported in this event, which occurs when the `DataInterval` has elapsed.

	---
	## Parameters:
	*   `counts`: The pulse count of the signal
	*   `timeChange`: The change in elapsed time since the last change
	*/
	public let countChange = Event<FrequencyCounter, (counts: UInt64, timeChange: Double)> ()
	let nativeCountChangeHandler : PhidgetFrequencyCounter_OnCountChangeCallback = { ch, ctx, counts, timeChange in
		let me = Unmanaged<FrequencyCounter>.fromOpaque(ctx!).takeUnretainedValue()
		me.countChange.raise(me, (counts, timeChange));
	}

	/**
	The most recent frequency value the channel has measured will be reported in this event, which occurs when the `DataInterval` has elapsed.

	---
	## Parameters:
	*   `frequency`: The calculated frequency of the signal
	*/
	public let frequencyChange = Event<FrequencyCounter, Double> ()
	let nativeFrequencyChangeHandler : PhidgetFrequencyCounter_OnFrequencyChangeCallback = { ch, ctx, frequency in
		let me = Unmanaged<FrequencyCounter>.fromOpaque(ctx!).takeUnretainedValue()
		me.frequencyChange.raise(me, frequency);
	}

}
