import Foundation
//import Phidget22

/**
The Digital Output class is used to control digital logic outputs and LED outputs on Phidgets boards.
*/
public class DigitalOutputBase : Phidget {

	public init() {
		var h: PhidgetHandle?
		PhidgetDigitalOutput_create(&h)
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
			PhidgetDigitalOutput_delete(&chandle)
		}
	}

	/**
	The `DutyCycle` represents the fraction of time the output is on (high).

	*   A `DutyCycle` of 1.0 translates to a high output, a `DutyCycle` of 0 translates to a low output.
	*   A `DutyCycle` of 0.5 translates to an output that is high half the time, which results in an average output voltage of (output voltage x 0.5)
	*   You can use the `DutyCycle` to create a dimming effect on LEDs.

	- returns:
	The duty cycle value

	- throws:
	An error or type `PhidgetError`
	*/
	public func getDutyCycle() throws -> Double {
		let result: PhidgetReturnCode
		var dutyCycle: Double = 0
		result = PhidgetDigitalOutput_getDutyCycle(chandle, &dutyCycle)
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
		return dutyCycle
	}

	/**
	The `DutyCycle` represents the fraction of time the output is on (high).

	*   A `DutyCycle` of 1.0 translates to a high output, a `DutyCycle` of 0 translates to a low output.
	*   A `DutyCycle` of 0.5 translates to an output that is high half the time, which results in an average output voltage of (output voltage x 0.5)
	*   You can use the `DutyCycle` to create a dimming effect on LEDs.

	- throws:
	An error or type `PhidgetError`

	- parameters:
		- dutyCycle: The duty cycle value
	*/
	public func setDutyCycle(_ dutyCycle: Double) throws {
		let result: PhidgetReturnCode
		result = PhidgetDigitalOutput_setDutyCycle(chandle, dutyCycle)
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
	}

	/**
	The `DutyCycle` represents the fraction of time the output is on (high).

	*   A `DutyCycle` of 1.0 translates to a high output, a `DutyCycle` of 0 translates to a low output.
	*   A `DutyCycle` of 0.5 translates to an output that is high half the time, which results in an average output voltage of (output voltage x 0.5)
	*   You can use the `DutyCycle` to create a dimming effect on LEDs.

	- parameters:
		- dutyCycle: The duty cycle value
		- completion: Asynchronous completion callback
	*/
	public func setDutyCycle(_ dutyCycle: Double, completion: @escaping (ErrorCode) -> ()) {
		let callback = AsyncCallback(completion)
		let callbackCtx = Unmanaged.passRetained(callback)
		PhidgetDigitalOutput_setDutyCycle_async(chandle, dutyCycle, AsyncCallback.nativeAsyncCallback, UnsafeMutableRawPointer(callbackCtx.toOpaque()))
	}

	/**
	The minimum value that `DutyCycle` can be set to.

	- returns:
	The duty cycle value

	- throws:
	An error or type `PhidgetError`
	*/
	public func getMinDutyCycle() throws -> Double {
		let result: PhidgetReturnCode
		var minDutyCycle: Double = 0
		result = PhidgetDigitalOutput_getMinDutyCycle(chandle, &minDutyCycle)
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
		return minDutyCycle
	}

	/**
	The maximum value that `DutyCycle` can be set to.

	- returns:
	The duty cycle value

	- throws:
	An error or type `PhidgetError`
	*/
	public func getMaxDutyCycle() throws -> Double {
		let result: PhidgetReturnCode
		var maxDutyCycle: Double = 0
		result = PhidgetDigitalOutput_getMaxDutyCycle(chandle, &maxDutyCycle)
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
		return maxDutyCycle
	}

	/**
	Enables the **failsafe** feature for the channel, with the specified **failsafe time**.

	Enabling the failsafe feature starts a recurring **failsafe timer** for the channel. Once the failsafe is enabled, the timer must be reset within the specified time or the channel will enter a **failsafe state**. For Digital Output channels, this will set the output State to FALSE. The failsafe timer can be reset by using any of the following API calls:

	*   `setDutyCycle()`
	*   `setState()`
	*   `setFrequency()`
	*   `resetFailsafe()`

	For more information about failsafe, visit our [Failsafe Guide](/docs/Failsafe_Guide).

	- throws:
	An error or type `PhidgetError`

	- parameters:
		- failsafeTime: Failsafe timeout in milliseconds
	*/
	public func enableFailsafe(failsafeTime: UInt32) throws {
		let result: PhidgetReturnCode
		result = PhidgetDigitalOutput_enableFailsafe(chandle, failsafeTime)
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
	}

	/**
	The minimum value that `failsafeTime` can be set to when calling `enableFailsafe()`.

	- returns:
	The failsafe time

	- throws:
	An error or type `PhidgetError`
	*/
	public func getMinFailsafeTime() throws -> UInt32 {
		let result: PhidgetReturnCode
		var minFailsafeTime: UInt32 = 0
		result = PhidgetDigitalOutput_getMinFailsafeTime(chandle, &minFailsafeTime)
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
		return minFailsafeTime
	}

	/**
	The maximum value that `failsafeTime` can be set to when calling `enableFailsafe()`.

	- returns:
	The failsafe time

	- throws:
	An error or type `PhidgetError`
	*/
	public func getMaxFailsafeTime() throws -> UInt32 {
		let result: PhidgetReturnCode
		var maxFailsafeTime: UInt32 = 0
		result = PhidgetDigitalOutput_getMaxFailsafeTime(chandle, &maxFailsafeTime)
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
		return maxFailsafeTime
	}

	/**
	The `Frequency` parameter sets the PWM frequency for all frequency-settable PWM outputs on the board.

	- returns:
	The PWM frequency

	- throws:
	An error or type `PhidgetError`
	*/
	public func getFrequency() throws -> Double {
		let result: PhidgetReturnCode
		var frequency: Double = 0
		result = PhidgetDigitalOutput_getFrequency(chandle, &frequency)
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
		return frequency
	}

	/**
	The `Frequency` parameter sets the PWM frequency for all frequency-settable PWM outputs on the board.

	- throws:
	An error or type `PhidgetError`

	- parameters:
		- frequency: The PWM frequency
	*/
	public func setFrequency(_ frequency: Double) throws {
		let result: PhidgetReturnCode
		result = PhidgetDigitalOutput_setFrequency(chandle, frequency)
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
	}

	/**
	The minimum value that `Frequency` can be set to.

	- returns:
	The frequency

	- throws:
	An error or type `PhidgetError`
	*/
	public func getMinFrequency() throws -> Double {
		let result: PhidgetReturnCode
		var minFrequency: Double = 0
		result = PhidgetDigitalOutput_getMinFrequency(chandle, &minFrequency)
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
		return minFrequency
	}

	/**
	The maximum value that `Frequency` can be set to.

	- returns:
	The frequency

	- throws:
	An error or type `PhidgetError`
	*/
	public func getMaxFrequency() throws -> Double {
		let result: PhidgetReturnCode
		var maxFrequency: Double = 0
		result = PhidgetDigitalOutput_getMaxFrequency(chandle, &maxFrequency)
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
		return maxFrequency
	}

	/**
	The `LEDCurrentLimit` is the maximum amount of current that the controller will provide to the output.

	*   Reference the data sheet of the LED you are using before setting this value.

	- returns:
	The current limit value

	- throws:
	An error or type `PhidgetError`
	*/
	public func getLEDCurrentLimit() throws -> Double {
		let result: PhidgetReturnCode
		var lEDCurrentLimit: Double = 0
		result = PhidgetDigitalOutput_getLEDCurrentLimit(chandle, &lEDCurrentLimit)
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
		return lEDCurrentLimit
	}

	/**
	The `LEDCurrentLimit` is the maximum amount of current that the controller will provide to the output.

	*   Reference the data sheet of the LED you are using before setting this value.

	- throws:
	An error or type `PhidgetError`

	- parameters:
		- LEDCurrentLimit: The current limit value
	*/
	public func setLEDCurrentLimit(_ LEDCurrentLimit: Double) throws {
		let result: PhidgetReturnCode
		result = PhidgetDigitalOutput_setLEDCurrentLimit(chandle, LEDCurrentLimit)
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
	}

	/**
	The `LEDCurrentLimit` is the maximum amount of current that the controller will provide to the output.

	*   Reference the data sheet of the LED you are using before setting this value.

	- parameters:
		- LEDCurrentLimit: The current limit value
		- completion: Asynchronous completion callback
	*/
	public func setLEDCurrentLimit(_ LEDCurrentLimit: Double, completion: @escaping (ErrorCode) -> ()) {
		let callback = AsyncCallback(completion)
		let callbackCtx = Unmanaged.passRetained(callback)
		PhidgetDigitalOutput_setLEDCurrentLimit_async(chandle, LEDCurrentLimit, AsyncCallback.nativeAsyncCallback, UnsafeMutableRawPointer(callbackCtx.toOpaque()))
	}

	/**
	The minimum value that `LEDCurrentLimit` can be set to.

	- returns:
	The current limit value

	- throws:
	An error or type `PhidgetError`
	*/
	public func getMinLEDCurrentLimit() throws -> Double {
		let result: PhidgetReturnCode
		var minLEDCurrentLimit: Double = 0
		result = PhidgetDigitalOutput_getMinLEDCurrentLimit(chandle, &minLEDCurrentLimit)
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
		return minLEDCurrentLimit
	}

	/**
	The maximum value that `LEDCurrentLimit` can be set to.

	- returns:
	The current limit value

	- throws:
	An error or type `PhidgetError`
	*/
	public func getMaxLEDCurrentLimit() throws -> Double {
		let result: PhidgetReturnCode
		var maxLEDCurrentLimit: Double = 0
		result = PhidgetDigitalOutput_getMaxLEDCurrentLimit(chandle, &maxLEDCurrentLimit)
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
		return maxLEDCurrentLimit
	}

	/**
	The `LEDForwardVoltage` is the voltage that will be available to your LED.

	*   Reference the data sheet of the LED you are using before setting this value. Choose the `LEDForwardVoltage` that is closest to the forward voltage specified in the data sheet.
	*   This forward voltage is shared for all channels on this device. Setting the LEDForwardVoltage on any channel will set the LEDForwardVoltage for all channels on the device.

	- returns:
	The forward voltage value

	- throws:
	An error or type `PhidgetError`
	*/
	public func getLEDForwardVoltage() throws -> LEDForwardVoltage {
		let result: PhidgetReturnCode
		var lEDForwardVoltage: PhidgetDigitalOutput_LEDForwardVoltage = LED_FORWARD_VOLTAGE_1_7V
		result = PhidgetDigitalOutput_getLEDForwardVoltage(chandle, &lEDForwardVoltage)
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
		return LEDForwardVoltage(rawValue: lEDForwardVoltage.rawValue)!
	}

	/**
	The `LEDForwardVoltage` is the voltage that will be available to your LED.

	*   Reference the data sheet of the LED you are using before setting this value. Choose the `LEDForwardVoltage` that is closest to the forward voltage specified in the data sheet.
	*   This forward voltage is shared for all channels on this device. Setting the LEDForwardVoltage on any channel will set the LEDForwardVoltage for all channels on the device.

	- throws:
	An error or type `PhidgetError`

	- parameters:
		- LEDForwardVoltage: The forward voltage value
	*/
	public func setLEDForwardVoltage(_ LEDForwardVoltage: LEDForwardVoltage) throws {
		let result: PhidgetReturnCode
		result = PhidgetDigitalOutput_setLEDForwardVoltage(chandle, PhidgetDigitalOutput_LEDForwardVoltage(LEDForwardVoltage.rawValue))
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
	}

	/**
	Resets the failsafe timer, if one has been set. See `enableFailsafe()` for details.

	This function will fail if no failsafe timer has been set for the channel.

	- throws:
	An error or type `PhidgetError`
	*/
	public func resetFailsafe() throws {
		let result: PhidgetReturnCode
		result = PhidgetDigitalOutput_resetFailsafe(chandle)
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
	}

	/**
	The `State` will indicate whether the output is high (TRUE) or low (FALSE).

	*   If a `DutyCycle` has been set, the state will return as TRUE if the DutyCycle is above 0.5, or FALSE otherwise.

	- returns:
	The state value

	- throws:
	An error or type `PhidgetError`
	*/
	public func getState() throws -> Bool {
		let result: PhidgetReturnCode
		var state: Int32 = 0
		result = PhidgetDigitalOutput_getState(chandle, &state)
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
		return (state == 0 ? false : true)
	}

	/**
	The `State` will dictate whether the output is constantly high (TRUE) or low (FALSE).

	*   This will override any `DutyCycle` that may have been set on the channel.
	*   Setting the `State` to TRUE is the same as setting `DutyCycle` to 1.0, and setting the `State` to FALSE is the same as setting a `DutyCycle` of 0.0.

	- throws:
	An error or type `PhidgetError`

	- parameters:
		- state: The state value
	*/
	public func setState(_ state: Bool) throws {
		let result: PhidgetReturnCode
		result = PhidgetDigitalOutput_setState(chandle, (state ? 1 : 0))
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
	}

	/**
	The `State` will dictate whether the output is constantly high (TRUE) or low (FALSE).

	*   This will override any `DutyCycle` that may have been set on the channel.
	*   Setting the `State` to TRUE is the same as setting `DutyCycle` to 1.0, and setting the `State` to FALSE is the same as setting a `DutyCycle` of 0.0.

	- parameters:
		- state: The state value
		- completion: Asynchronous completion callback
	*/
	public func setState(_ state: Bool, completion: @escaping (ErrorCode) -> ()) {
		let callback = AsyncCallback(completion)
		let callbackCtx = Unmanaged.passRetained(callback)
		PhidgetDigitalOutput_setState_async(chandle, (state ? 1 : 0), AsyncCallback.nativeAsyncCallback, UnsafeMutableRawPointer(callbackCtx.toOpaque()))
	}

}
