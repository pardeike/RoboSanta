import Foundation
//import Phidget22

/**
The Motor Position Controller class controlls the position, velocity and acceleration of the attached motor. It also contains various other control and monitoring functions that aid in the control of the motor.

For specifics on how to use this class, we recommend watching our video on the [Phidget Motor Position Controller](https://www.youtube.com/watch?v=0cQlxNd7dk4) class.
*/
public class MotorPositionControllerBase : Phidget {

	public init() {
		var h: PhidgetHandle?
		PhidgetMotorPositionController_create(&h)
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
			PhidgetMotorPositionController_delete(&chandle)
		}
	}

	/**
	The rate at which the controller can change the motor's velocity.

	*   Use the `RescaleFactor` to convert the units of this property to more intuitive units, such as rotations or degrees.

	  
	For more information about `Acceleration`, visit our [MotorPositionController API Guide](/docs/MotorPositionController_API_Guide#Acceleration)

	- returns:
	The acceleration value

	- throws:
	An error or type `PhidgetError`
	*/
	public func getAcceleration() throws -> Double {
		let result: PhidgetReturnCode
		var acceleration: Double = 0
		result = PhidgetMotorPositionController_getAcceleration(chandle, &acceleration)
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
		return acceleration
	}

	/**
	The rate at which the controller can change the motor's velocity.

	*   Use the `RescaleFactor` to convert the units of this property to more intuitive units, such as rotations or degrees.

	  
	For more information about `Acceleration`, visit our [MotorPositionController API Guide](/docs/MotorPositionController_API_Guide#Acceleration)

	- throws:
	An error or type `PhidgetError`

	- parameters:
		- acceleration: The acceleration value
	*/
	public func setAcceleration(_ acceleration: Double) throws {
		let result: PhidgetReturnCode
		result = PhidgetMotorPositionController_setAcceleration(chandle, acceleration)
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
	}

	/**
	The minimum value that `Acceleration` can be set to.

	*   Use the `RescaleFactor` to convert the units of this property to more intuitive units, such as rotations or degrees.

	- returns:
	The acceleration value.

	- throws:
	An error or type `PhidgetError`
	*/
	public func getMinAcceleration() throws -> Double {
		let result: PhidgetReturnCode
		var minAcceleration: Double = 0
		result = PhidgetMotorPositionController_getMinAcceleration(chandle, &minAcceleration)
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
		return minAcceleration
	}

	/**
	The maximum value that `Acceleration` can be set to.

	*   Use the `RescaleFactor` to convert the units of this property to more intuitive units, such as rotations or degrees.

	- returns:
	The acceleration value.

	- throws:
	An error or type `PhidgetError`
	*/
	public func getMaxAcceleration() throws -> Double {
		let result: PhidgetReturnCode
		var maxAcceleration: Double = 0
		result = PhidgetMotorPositionController_getMaxAcceleration(chandle, &maxAcceleration)
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
		return maxAcceleration
	}

	/**
	The current limit that the controller is actively following. The `SurgeCurrentLimit`, `CurrentLimit`, and temperature will impact this value.

	- returns:
	The active current limit value

	- throws:
	An error or type `PhidgetError`
	*/
	public func getActiveCurrentLimit() throws -> Double {
		let result: PhidgetReturnCode
		var activeCurrentLimit: Double = 0
		result = PhidgetMotorPositionController_getActiveCurrentLimit(chandle, &activeCurrentLimit)
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
		return activeCurrentLimit
	}

	/**
	The controller will limit the current through the motor to the `CurrentLimit` value.

	  
	For more information about `CurrentLimit`, visit our [MotorPositionController API Guide](/docs/MotorPositionController_API_Guide#Current_Limit)

	- returns:
	Motor current limit

	- throws:
	An error or type `PhidgetError`
	*/
	public func getCurrentLimit() throws -> Double {
		let result: PhidgetReturnCode
		var currentLimit: Double = 0
		result = PhidgetMotorPositionController_getCurrentLimit(chandle, &currentLimit)
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
		return currentLimit
	}

	/**
	The controller will limit the current through the motor to the `CurrentLimit` value.

	  
	For more information about `CurrentLimit`, visit our [MotorPositionController API Guide](/docs/MotorPositionController_API_Guide#Current_Limit)

	- throws:
	An error or type `PhidgetError`

	- parameters:
		- currentLimit: Motor current limit
	*/
	public func setCurrentLimit(_ currentLimit: Double) throws {
		let result: PhidgetReturnCode
		result = PhidgetMotorPositionController_setCurrentLimit(chandle, currentLimit)
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
	}

	/**
	The minimum current limit that can be set for the device.

	- returns:
	Minimum current limit

	- throws:
	An error or type `PhidgetError`
	*/
	public func getMinCurrentLimit() throws -> Double {
		let result: PhidgetReturnCode
		var minCurrentLimit: Double = 0
		result = PhidgetMotorPositionController_getMinCurrentLimit(chandle, &minCurrentLimit)
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
		return minCurrentLimit
	}

	/**
	The maximum current limit that can be set for the device.

	- returns:
	Maximum current limit

	- throws:
	An error or type `PhidgetError`
	*/
	public func getMaxCurrentLimit() throws -> Double {
		let result: PhidgetReturnCode
		var maxCurrentLimit: Double = 0
		result = PhidgetMotorPositionController_getMaxCurrentLimit(chandle, &maxCurrentLimit)
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
		return maxCurrentLimit
	}

	/**
	Depending on power supply voltage and motor coil inductance, current through the motor can change relatively slowly or extremely rapidly. A physically larger DC Motor will typically have a lower inductance, requiring a higher current regulator gain. A higher power supply voltage will result in motor current changing more rapidly, requiring a higher current regulator gain. If the current regulator gain is too small, spikes in current will occur, causing large variations in torque, and possibly damaging the motor controller. If the current regulator gain is too high, the current will jitter, causing the motor to sound 'rough', especially when changing directions. Each DC Motor we sell specifies a suitable current regulator gain.

	- returns:
	Current Regulator Gain

	- throws:
	An error or type `PhidgetError`
	*/
	public func getCurrentRegulatorGain() throws -> Double {
		let result: PhidgetReturnCode
		var currentRegulatorGain: Double = 0
		result = PhidgetMotorPositionController_getCurrentRegulatorGain(chandle, &currentRegulatorGain)
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
		return currentRegulatorGain
	}

	/**
	Depending on power supply voltage and motor coil inductance, current through the motor can change relatively slowly or extremely rapidly. A physically larger DC Motor will typically have a lower inductance, requiring a higher current regulator gain. A higher power supply voltage will result in motor current changing more rapidly, requiring a higher current regulator gain. If the current regulator gain is too small, spikes in current will occur, causing large variations in torque, and possibly damaging the motor controller. If the current regulator gain is too high, the current will jitter, causing the motor to sound 'rough', especially when changing directions. Each DC Motor we sell specifies a suitable current regulator gain.

	- throws:
	An error or type `PhidgetError`

	- parameters:
		- currentRegulatorGain: Current Regulator Gain
	*/
	public func setCurrentRegulatorGain(_ currentRegulatorGain: Double) throws {
		let result: PhidgetReturnCode
		result = PhidgetMotorPositionController_setCurrentRegulatorGain(chandle, currentRegulatorGain)
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
	}

	/**
	The minimum current regulator gain for the device.

	- returns:
	Minimum current regulator gain

	- throws:
	An error or type `PhidgetError`
	*/
	public func getMinCurrentRegulatorGain() throws -> Double {
		let result: PhidgetReturnCode
		var minCurrentRegulatorGain: Double = 0
		result = PhidgetMotorPositionController_getMinCurrentRegulatorGain(chandle, &minCurrentRegulatorGain)
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
		return minCurrentRegulatorGain
	}

	/**
	The maximum current regulator gain for the device.

	- returns:
	Maximum current regulator gain

	- throws:
	An error or type `PhidgetError`
	*/
	public func getMaxCurrentRegulatorGain() throws -> Double {
		let result: PhidgetReturnCode
		var maxCurrentRegulatorGain: Double = 0
		result = PhidgetMotorPositionController_getMaxCurrentRegulatorGain(chandle, &maxCurrentRegulatorGain)
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
		return maxCurrentRegulatorGain
	}

	/**
	The `DataInterval` is the time that must elapse before the channel will fire another `PositionChange` / `DutyCycleUpdate` event.

	*   The data interval is bounded by `MinDataInterval` and `MaxDataInterval`.

	- returns:
	The data interval value

	- throws:
	An error or type `PhidgetError`
	*/
	public func getDataInterval() throws -> UInt32 {
		let result: PhidgetReturnCode
		var dataInterval: UInt32 = 0
		result = PhidgetMotorPositionController_getDataInterval(chandle, &dataInterval)
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
		return dataInterval
	}

	/**
	The `DataInterval` is the time that must elapse before the channel will fire another `PositionChange` / `DutyCycleUpdate` event.

	*   The data interval is bounded by `MinDataInterval` and `MaxDataInterval`.

	- throws:
	An error or type `PhidgetError`

	- parameters:
		- dataInterval: The data interval value
	*/
	public func setDataInterval(_ dataInterval: UInt32) throws {
		let result: PhidgetReturnCode
		result = PhidgetMotorPositionController_setDataInterval(chandle, dataInterval)
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
		result = PhidgetMotorPositionController_getMinDataInterval(chandle, &minDataInterval)
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
		result = PhidgetMotorPositionController_getMaxDataInterval(chandle, &maxDataInterval)
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
		result = PhidgetMotorPositionController_getDataRate(chandle, &dataRate)
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
		result = PhidgetMotorPositionController_setDataRate(chandle, dataRate)
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
		result = PhidgetMotorPositionController_getMinDataRate(chandle, &minDataRate)
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
		result = PhidgetMotorPositionController_getMaxDataRate(chandle, &maxDataRate)
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
		return maxDataRate
	}

	/**
	`DeadBand` specifies a a region around the `TargetPosition` (`TargetPosition` \+/\- `DeadBand`) where control of the motor is relaxed.

	*   Use the `RescaleFactor` to convert the units of this property to more intuitive units, such as rotations or degrees.

	  
	For more information about `DeadBand`, visit our [MotorPositionController API Guide](/docs/MotorPositionController_API_Guide#Deadband)

	- returns:
	The dead band value

	- throws:
	An error or type `PhidgetError`
	*/
	public func getDeadBand() throws -> Double {
		let result: PhidgetReturnCode
		var deadBand: Double = 0
		result = PhidgetMotorPositionController_getDeadBand(chandle, &deadBand)
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
		return deadBand
	}

	/**
	`DeadBand` specifies a a region around the `TargetPosition` (`TargetPosition` \+/\- `DeadBand`) where control of the motor is relaxed.

	*   Use the `RescaleFactor` to convert the units of this property to more intuitive units, such as rotations or degrees.

	  
	For more information about `DeadBand`, visit our [MotorPositionController API Guide](/docs/MotorPositionController_API_Guide#Deadband)

	- throws:
	An error or type `PhidgetError`

	- parameters:
		- deadBand: The dead band value
	*/
	public func setDeadBand(_ deadBand: Double) throws {
		let result: PhidgetReturnCode
		result = PhidgetMotorPositionController_setDeadBand(chandle, deadBand)
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
	}

	/**
	The most recent `DutyCycle` value that the controller has reported.

	*   This value will be between -1 and 1 where a sign change (±) is indicitave of a direction change.
	*   `DutyCycle` is an indication of the average voltage across the motor. At a constant load, an increase in `DutyCycle` indicates an increase in motor speed.

	  
	For more information about `DutyCycle`, visit our [MotorPositionController API Guide](/docs/MotorPositionController_API_Guide#Duty_Cycle)

	- returns:
	The duty cycle value.

	- throws:
	An error or type `PhidgetError`
	*/
	public func getDutyCycle() throws -> Double {
		let result: PhidgetReturnCode
		var dutyCycle: Double = 0
		result = PhidgetMotorPositionController_getDutyCycle(chandle, &dutyCycle)
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
		return dutyCycle
	}

	/**
	When engaged, the motor has the ability to be positioned. When disengaged, the controller will stop powering to your motor, it will instead be in a freewheel state.

	  
	For more information about `Engaged`, visit our [MotorPositionController API Guide](/docs/MotorPositionController_API_Guide#Engage_Motor)

	- returns:
	The engaged value.

	- throws:
	An error or type `PhidgetError`
	*/
	public func getEngaged() throws -> Bool {
		let result: PhidgetReturnCode
		var engaged: Int32 = 0
		result = PhidgetMotorPositionController_getEngaged(chandle, &engaged)
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
		return (engaged == 0 ? false : true)
	}

	/**
	When engaged, the motor has the ability to be positioned. When disengaged, the controller will stop powering to your motor, it will instead be in a freewheel state.

	  
	For more information about `Engaged`, visit our [MotorPositionController API Guide](/docs/MotorPositionController_API_Guide#Engage_Motor)

	- throws:
	An error or type `PhidgetError`

	- parameters:
		- engaged: The engaged value.
	*/
	public func setEngaged(_ engaged: Bool) throws {
		let result: PhidgetReturnCode
		result = PhidgetMotorPositionController_setEngaged(chandle, (engaged ? 1 : 0))
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
	}

	/**
	This controller uses trapezoidal motion profiling combined with a PID loop to accurately track position. The `ExpectedPosition` represents the current position the controller is tracking along the trapezoidal motion curve. The error of your PID loop is calculated by taking the difference of `Position` and `ExpectedPosition`. You can use this value to verify your controller is working as expected.

	*   Set `EnableExpectedPosition` to **TRUE** to enable the change event for this property.
	*   Use the `RescaleFactor` to convert the units of this property to more intuitive units, such as rotations or degrees.

	- returns:
	The expected position value

	- throws:
	An error or type `PhidgetError`
	*/
	public func getExpectedPosition() throws -> Double {
		let result: PhidgetReturnCode
		var expectedPosition: Double = 0
		result = PhidgetMotorPositionController_getExpectedPosition(chandle, &expectedPosition)
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
		return expectedPosition
	}

	/**
	When enabled, the `ExpectedPosition` will be sent back from the controller.

	- throws:
	An error or type `PhidgetError`

	- parameters:
		- enableExpectedPosition: Enable expected position feedback
	*/
	public func setEnableExpectedPosition(_ enableExpectedPosition: Bool) throws {
		let result: PhidgetReturnCode
		result = PhidgetMotorPositionController_setEnableExpectedPosition(chandle, (enableExpectedPosition ? 1 : 0))
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
	}

	/**
	When enabled, the `ExpectedPosition` will be sent back from the controller.

	- returns:
	Enable expected position feedback

	- throws:
	An error or type `PhidgetError`
	*/
	public func getEnableExpectedPosition() throws -> Bool {
		let result: PhidgetReturnCode
		var enableExpectedPosition: Int32 = 0
		result = PhidgetMotorPositionController_getEnableExpectedPosition(chandle, &enableExpectedPosition)
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
		return (enableExpectedPosition == 0 ? false : true)
	}

	/**
	Enables the **failsafe** feature for the channel, with the specified **failsafe time**.

	Enabling the failsafe feature starts a recurring **failsafe timer** for the channel. Once the failsafe is enabled, the timer must be reset within the specified time or the channel will enter a **failsafe state**. For Motor Position Controller channels, this will cut power to the motor, allowing it to coast (freewheel) instead. The failsafe timer can be reset by using any API call **_except_** for the following:

	*   `setRescaleFactor()`
	*   `addPositionOffset()`
	*   `setNormalizePID()`
	*   'get' API calls

	For more information about failsafe, visit our [Failsafe Guide](/docs/Failsafe_Guide).

	- throws:
	An error or type `PhidgetError`

	- parameters:
		- failsafeTime: Failsafe timeout in milliseconds
	*/
	public func enableFailsafe(failsafeTime: UInt32) throws {
		let result: PhidgetReturnCode
		result = PhidgetMotorPositionController_enableFailsafe(chandle, failsafeTime)
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
	}

	/**
	This setting allows you to choose whether motor will forcibly stop once it enters a **FAILSAFE** state.

	*   A setting of FALSE will simply stop applying power to the motor, allowing it to spin down naturally.
	*   A setting of TRUE will apply braking up to the `FailsafeCurrentLimit`, actively stopping the motor

	  
	For more information about `FailsafeBrakingEnabled`, visit our [MotorPositionController API Guide](/docs/MotorPositionController_API_Guide#Failsafe_Braking_Enabled)

	- returns:
	Enables failsafe braking

	- throws:
	An error or type `PhidgetError`
	*/
	public func getFailsafeBrakingEnabled() throws -> Bool {
		let result: PhidgetReturnCode
		var failsafeBrakingEnabled: Int32 = 0
		result = PhidgetMotorPositionController_getFailsafeBrakingEnabled(chandle, &failsafeBrakingEnabled)
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
		return (failsafeBrakingEnabled == 0 ? false : true)
	}

	/**
	This setting allows you to choose whether motor will forcibly stop once it enters a **FAILSAFE** state.

	*   A setting of FALSE will simply stop applying power to the motor, allowing it to spin down naturally.
	*   A setting of TRUE will apply braking up to the `FailsafeCurrentLimit`, actively stopping the motor

	  
	For more information about `FailsafeBrakingEnabled`, visit our [MotorPositionController API Guide](/docs/MotorPositionController_API_Guide#Failsafe_Braking_Enabled)

	- throws:
	An error or type `PhidgetError`

	- parameters:
		- failsafeBrakingEnabled: Enables failsafe braking
	*/
	public func setFailsafeBrakingEnabled(_ failsafeBrakingEnabled: Bool) throws {
		let result: PhidgetReturnCode
		result = PhidgetMotorPositionController_setFailsafeBrakingEnabled(chandle, (failsafeBrakingEnabled ? 1 : 0))
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
	}

	/**
	When the controller enters a **FAILSAFE** state, the controller will limit the current through the motor to the `FailsafeCurrentLimit` value.

	  
	For more information about `FailsafeCurrentLimit`, visit our [MotorPositionController API Guide](/docs/MotorPositionController_API_Guide#Failsafe_Current_Limit)

	- returns:
	The failsafe current limit value

	- throws:
	An error or type `PhidgetError`
	*/
	public func getFailsafeCurrentLimit() throws -> Double {
		let result: PhidgetReturnCode
		var failsafeCurrentLimit: Double = 0
		result = PhidgetMotorPositionController_getFailsafeCurrentLimit(chandle, &failsafeCurrentLimit)
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
		return failsafeCurrentLimit
	}

	/**
	When the controller enters a **FAILSAFE** state, the controller will limit the current through the motor to the `FailsafeCurrentLimit` value.

	  
	For more information about `FailsafeCurrentLimit`, visit our [MotorPositionController API Guide](/docs/MotorPositionController_API_Guide#Failsafe_Current_Limit)

	- throws:
	An error or type `PhidgetError`

	- parameters:
		- failsafeCurrentLimit: The failsafe current limit value
	*/
	public func setFailsafeCurrentLimit(_ failsafeCurrentLimit: Double) throws {
		let result: PhidgetReturnCode
		result = PhidgetMotorPositionController_setFailsafeCurrentLimit(chandle, failsafeCurrentLimit)
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
		result = PhidgetMotorPositionController_getMinFailsafeTime(chandle, &minFailsafeTime)
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
		result = PhidgetMotorPositionController_getMaxFailsafeTime(chandle, &maxFailsafeTime)
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
		return maxFailsafeTime
	}

	/**
	The `FanMode` dictates the operating condition of the fan.

	*   Choose between on, off, or automatic (based on temperature).
	*   If the `FanMode` is set to automatic, the fan will turn on when the temperature reaches 70°C and it will remain on until the temperature falls below 55°C.
	*   If the `FanMode` is off, the controller will still turn on the fan if the temperature reaches 85°C and it will remain on until it falls below 70°C.

	- returns:
	The fan mode

	- throws:
	An error or type `PhidgetError`
	*/
	public func getFanMode() throws -> FanMode {
		let result: PhidgetReturnCode
		var fanMode: Phidget_FanMode = FAN_MODE_OFF
		result = PhidgetMotorPositionController_getFanMode(chandle, &fanMode)
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
		return FanMode(rawValue: fanMode.rawValue)!
	}

	/**
	The `FanMode` dictates the operating condition of the fan.

	*   Choose between on, off, or automatic (based on temperature).
	*   If the `FanMode` is set to automatic, the fan will turn on when the temperature reaches 70°C and it will remain on until the temperature falls below 55°C.
	*   If the `FanMode` is off, the controller will still turn on the fan if the temperature reaches 85°C and it will remain on until it falls below 70°C.

	- throws:
	An error or type `PhidgetError`

	- parameters:
		- fanMode: The fan mode
	*/
	public func setFanMode(_ fanMode: FanMode) throws {
		let result: PhidgetReturnCode
		result = PhidgetMotorPositionController_setFanMode(chandle, Phidget_FanMode(fanMode.rawValue))
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
	}

	/**
	The controller will attempt to measure the inductance of your motor when opened. This value is used to improve control of the motor.

	*   Set this value during the `Phidget.Attach` event to skip motor characterization (including the audible beeps). You can use a previously saved `Inductance` value, or information from your motor's datasheet.

	  
	For more information about `Inductance`, visit our [MotorPositionController API Guide](/docs/MotorPositionController_API_Guide#Motor_Inductance)

	- returns:
	The inductance of your motor

	- throws:
	An error or type `PhidgetError`
	*/
	public func getInductance() throws -> Double {
		let result: PhidgetReturnCode
		var inductance: Double = 0
		result = PhidgetMotorPositionController_getInductance(chandle, &inductance)
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
		return inductance
	}

	/**
	The controller will attempt to measure the inductance of your motor when opened. This value is used to improve control of the motor.

	*   Set this value during the `Phidget.Attach` event to skip motor characterization (including the audible beeps). You can use a previously saved `Inductance` value, or information from your motor's datasheet.

	  
	For more information about `Inductance`, visit our [MotorPositionController API Guide](/docs/MotorPositionController_API_Guide#Motor_Inductance)

	- throws:
	An error or type `PhidgetError`

	- parameters:
		- inductance: The inductance of your motor
	*/
	public func setInductance(_ inductance: Double) throws {
		let result: PhidgetReturnCode
		result = PhidgetMotorPositionController_setInductance(chandle, inductance)
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
	}

	/**
	The minimum value that `Inductance` can be set to. See `Inductance` for details.

	- returns:
	The motor inductance value

	- throws:
	An error or type `PhidgetError`
	*/
	public func getMinInductance() throws -> Double {
		let result: PhidgetReturnCode
		var minInductance: Double = 0
		result = PhidgetMotorPositionController_getMinInductance(chandle, &minInductance)
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
		return minInductance
	}

	/**
	The maximum value that `Inductance` can be set to. See `Inductance` for details.

	- returns:
	The motor inductance value

	- throws:
	An error or type `PhidgetError`
	*/
	public func getMaxInductance() throws -> Double {
		let result: PhidgetReturnCode
		var maxInductance: Double = 0
		result = PhidgetMotorPositionController_getMaxInductance(chandle, &maxInductance)
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
		return maxInductance
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
		result = PhidgetMotorPositionController_getIOMode(chandle, &iOMode)
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
		result = PhidgetMotorPositionController_setIOMode(chandle, Phidget_EncoderIOMode(IOMode.rawValue))
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
	}

	/**
	Derivative gain constant. A higher `Kd` will help reduce oscillations.

	  
	For more information about `Kd`, visit our [MotorPositionController API Guide](/docs/MotorPositionController_API_Guide#Tunings_Constants_(Kp,_Ki,_Kd))

	- returns:
	The Kd value.

	- throws:
	An error or type `PhidgetError`
	*/
	public func getKd() throws -> Double {
		let result: PhidgetReturnCode
		var kd: Double = 0
		result = PhidgetMotorPositionController_getKd(chandle, &kd)
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
		return kd
	}

	/**
	Derivative gain constant. A higher `Kd` will help reduce oscillations.

	  
	For more information about `Kd`, visit our [MotorPositionController API Guide](/docs/MotorPositionController_API_Guide#Tunings_Constants_(Kp,_Ki,_Kd))

	- throws:
	An error or type `PhidgetError`

	- parameters:
		- kd: The Kd value.
	*/
	public func setKd(_ kd: Double) throws {
		let result: PhidgetReturnCode
		result = PhidgetMotorPositionController_setKd(chandle, kd)
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
	}

	/**
	Integral gain constant. The integral term will help eliminate steady-state error.

	  
	For more information about `Ki`, visit our [MotorPositionController API Guide](/docs/MotorPositionController_API_Guide#Tunings_Constants_(Kp,_Ki,_Kd))

	- returns:
	The Ki value.

	- throws:
	An error or type `PhidgetError`
	*/
	public func getKi() throws -> Double {
		let result: PhidgetReturnCode
		var ki: Double = 0
		result = PhidgetMotorPositionController_getKi(chandle, &ki)
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
		return ki
	}

	/**
	Integral gain constant. The integral term will help eliminate steady-state error.

	  
	For more information about `Ki`, visit our [MotorPositionController API Guide](/docs/MotorPositionController_API_Guide#Tunings_Constants_(Kp,_Ki,_Kd))

	- throws:
	An error or type `PhidgetError`

	- parameters:
		- ki: The Ki value.
	*/
	public func setKi(_ ki: Double) throws {
		let result: PhidgetReturnCode
		result = PhidgetMotorPositionController_setKi(chandle, ki)
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
	}

	/**
	Proportional gain constant. A small `Kp` value will result in a less responsive controller, however, if `Kp` is too high, the system can become unstable.

	  
	For more information about `Kp`, visit our [MotorPositionController API Guide](/docs/MotorPositionController_API_Guide#Tunings_Constants_(Kp,_Ki,_Kd))

	- returns:
	The Kp value.

	- throws:
	An error or type `PhidgetError`
	*/
	public func getKp() throws -> Double {
		let result: PhidgetReturnCode
		var kp: Double = 0
		result = PhidgetMotorPositionController_getKp(chandle, &kp)
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
		return kp
	}

	/**
	Proportional gain constant. A small `Kp` value will result in a less responsive controller, however, if `Kp` is too high, the system can become unstable.

	  
	For more information about `Kp`, visit our [MotorPositionController API Guide](/docs/MotorPositionController_API_Guide#Tunings_Constants_(Kp,_Ki,_Kd))

	- throws:
	An error or type `PhidgetError`

	- parameters:
		- kp: The Kp value.
	*/
	public func setKp(_ kp: Double) throws {
		let result: PhidgetReturnCode
		result = PhidgetMotorPositionController_setKp(chandle, kp)
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
	}

	/**
	Set this parameter to TRUE to adjust PID math to standardized units.

	- returns:
	Set this parameter to TRUE to adjust PID math to standardized units.

	- throws:
	An error or type `PhidgetError`
	*/
	public func getNormalizePID() throws -> Bool {
		let result: PhidgetReturnCode
		var normalizePID: Int32 = 0
		result = PhidgetMotorPositionController_getNormalizePID(chandle, &normalizePID)
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
		return (normalizePID == 0 ? false : true)
	}

	/**
	Set this parameter to TRUE to adjust PID math to standardized units.

	- throws:
	An error or type `PhidgetError`

	- parameters:
		- normalizePID: Set this parameter to TRUE to adjust PID math to standardized units.
	*/
	public func setNormalizePID(_ normalizePID: Bool) throws {
		let result: PhidgetReturnCode
		result = PhidgetMotorPositionController_setNormalizePID(chandle, (normalizePID ? 1 : 0))
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
	}

	/**
	The most recent position value that the controller has reported.

	*   Use the `RescaleFactor` to convert the units of this property to more intuitive units, such as rotations or degrees.

	  
	For more information about `Position`, visit our [MotorPositionController API Guide](/docs/MotorPositionController_API_Guide#Position)

	- returns:
	The position value

	- throws:
	An error or type `PhidgetError`
	*/
	public func getPosition() throws -> Double {
		let result: PhidgetReturnCode
		var position: Double = 0
		result = PhidgetMotorPositionController_getPosition(chandle, &position)
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
		return position
	}

	/**
	The minimum value that `TargetPosition` can be set to.

	*   Use the `RescaleFactor` to convert the units of this property to more intuitive units, such as rotations or degrees.

	- returns:
	The position value

	- throws:
	An error or type `PhidgetError`
	*/
	public func getMinPosition() throws -> Double {
		let result: PhidgetReturnCode
		var minPosition: Double = 0
		result = PhidgetMotorPositionController_getMinPosition(chandle, &minPosition)
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
		return minPosition
	}

	/**
	The maximum value that `TargetPosition` can be set to.

	*   Use the `RescaleFactor` to convert the units of this property to more intuitive units, such as rotations or degrees.

	- returns:
	The position value

	- throws:
	An error or type `PhidgetError`
	*/
	public func getMaxPosition() throws -> Double {
		let result: PhidgetReturnCode
		var maxPosition: Double = 0
		result = PhidgetMotorPositionController_getMaxPosition(chandle, &maxPosition)
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
		return maxPosition
	}

	/**
	Adds an offset (positive or negative) to the current position. Useful for zeroing position.

	- throws:
	An error or type `PhidgetError`

	- parameters:
		- positionOffset: Amount to offset the position by
	*/
	public func addPositionOffset(positionOffset: Double) throws {
		let result: PhidgetReturnCode
		result = PhidgetMotorPositionController_addPositionOffset(chandle, positionOffset)
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
	}

	/**
	Determines whether the controller uses the hall effect sensors or an encoder for position information. This setting is locked in once the channel is `Engaged` and cannot be changed until the channel is reset.

	- returns:
	The position type selection

	- throws:
	An error or type `PhidgetError`
	*/
	public func getPositionType() throws -> PositionType {
		let result: PhidgetReturnCode
		var positionType: Phidget_PositionType = POSITION_TYPE_ENCODER
		result = PhidgetMotorPositionController_getPositionType(chandle, &positionType)
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
		return PositionType(rawValue: positionType.rawValue)!
	}

	/**
	Determines whether the controller uses the hall effect sensors or an encoder for position information. This setting is locked in once the channel is `Engaged` and cannot be changed until the channel is reset.

	- throws:
	An error or type `PhidgetError`

	- parameters:
		- positionType: The position type selection
	*/
	public func setPositionType(_ positionType: PositionType) throws {
		let result: PhidgetReturnCode
		result = PhidgetMotorPositionController_setPositionType(chandle, Phidget_PositionType(positionType.rawValue))
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
	}

	/**
	Change the units of your parameters so that your application is more intuitive.

	*   Units for `Position`, `TargetPosition`, `VelocityLimit`, `Acceleration`, and `DeadBand` can be set by the user through the `RescaleFactor`. The `RescaleFactor` allows you to use more intuitive units such as rotations, or degrees.

	  
	For more information about `RescaleFactor`, visit our [MotorPositionController API Guide](/docs/MotorPositionController_API_Guide#Rescale_Factor)

	- returns:
	The rescale factor value

	- throws:
	An error or type `PhidgetError`
	*/
	public func getRescaleFactor() throws -> Double {
		let result: PhidgetReturnCode
		var rescaleFactor: Double = 0
		result = PhidgetMotorPositionController_getRescaleFactor(chandle, &rescaleFactor)
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
		return rescaleFactor
	}

	/**
	Change the units of your parameters so that your application is more intuitive.

	*   Units for `Position`, `TargetPosition`, `VelocityLimit`, `Acceleration`, and `DeadBand` can be set by the user through the `RescaleFactor`. The `RescaleFactor` allows you to use more intuitive units such as rotations, or degrees.

	  
	For more information about `RescaleFactor`, visit our [MotorPositionController API Guide](/docs/MotorPositionController_API_Guide#Rescale_Factor)

	- throws:
	An error or type `PhidgetError`

	- parameters:
		- rescaleFactor: The rescale factor value
	*/
	public func setRescaleFactor(_ rescaleFactor: Double) throws {
		let result: PhidgetReturnCode
		result = PhidgetMotorPositionController_setRescaleFactor(chandle, rescaleFactor)
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
		result = PhidgetMotorPositionController_resetFailsafe(chandle)
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
	}

	/**
	Before reading this description, it is important to note the difference between the units of `StallVelocity` and `DutyCycle`.

	*   `DutyCycle` is a number between -1 and 1 with units of 'duty cycle'. It simply represents the average voltage across the motor.
	*   `StallVelocity` represents a real velocity (e.g. m/s, RPM, etc.) and the units are determined by the `RescaleFactor`. With a `RescaleFactor` of 1, the default units would be in commutations per second.

	If the load on your motor is large, your motor may begin rotating more slowly, or even fully stall. Depending on the voltage across your motor, this may result in a large amount of current through both the controller and the motor. In order to prevent damage in these situations, you can use the `StallVelocity` property.  
	  
	The `StallVelocity` should be set to the lowest velocity you would expect from your motor. The controller will then monitor the motor's velocity, as well as the `DutyCycle`, and prevent a 'dangerous stall' from occuring. If the controller detects a dangerous stall, it will immediately disengage the motor (i.e. `Engaged` will be set to false) and an error will be reported to your program.

	*   A 'dangerous stall' will occur faster when the `DutyCycle` is higher (i.e. when the average voltage across the motor is higher)
	*   A 'dangerous stall' will occur faster as (`StallVelocity` \- motor velocity) becomes larger .

	Setting `StallVelocity` to 0 will turn off stall protection functionality.

	- returns:
	The stall velocity value.

	- throws:
	An error or type `PhidgetError`
	*/
	public func getStallVelocity() throws -> Double {
		let result: PhidgetReturnCode
		var stallVelocity: Double = 0
		result = PhidgetMotorPositionController_getStallVelocity(chandle, &stallVelocity)
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
		return stallVelocity
	}

	/**
	Before reading this description, it is important to note the difference between the units of `StallVelocity` and `DutyCycle`.

	*   `DutyCycle` is a number between -1 and 1 with units of 'duty cycle'. It simply represents the average voltage across the motor.
	*   `StallVelocity` represents a real velocity (e.g. m/s, RPM, etc.) and the units are determined by the `RescaleFactor`. With a `RescaleFactor` of 1, the default units would be in commutations per second.

	If the load on your motor is large, your motor may begin rotating more slowly, or even fully stall. Depending on the voltage across your motor, this may result in a large amount of current through both the controller and the motor. In order to prevent damage in these situations, you can use the `StallVelocity` property.  
	  
	The `StallVelocity` should be set to the lowest velocity you would expect from your motor. The controller will then monitor the motor's velocity, as well as the `DutyCycle`, and prevent a 'dangerous stall' from occuring. If the controller detects a dangerous stall, it will immediately disengage the motor (i.e. `Engaged` will be set to false) and an error will be reported to your program.

	*   A 'dangerous stall' will occur faster when the `DutyCycle` is higher (i.e. when the average voltage across the motor is higher)
	*   A 'dangerous stall' will occur faster as (`StallVelocity` \- motor velocity) becomes larger .

	Setting `StallVelocity` to 0 will turn off stall protection functionality.

	- throws:
	An error or type `PhidgetError`

	- parameters:
		- stallVelocity: The stall velocity value.
	*/
	public func setStallVelocity(_ stallVelocity: Double) throws {
		let result: PhidgetReturnCode
		result = PhidgetMotorPositionController_setStallVelocity(chandle, stallVelocity)
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
	}

	/**
	The lower bound of `StallVelocity`.

	- returns:
	The velocity value

	- throws:
	An error or type `PhidgetError`
	*/
	public func getMinStallVelocity() throws -> Double {
		let result: PhidgetReturnCode
		var minStallVelocity: Double = 0
		result = PhidgetMotorPositionController_getMinStallVelocity(chandle, &minStallVelocity)
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
		return minStallVelocity
	}

	/**
	The upper bound of `StallVelocity`.

	- returns:
	The velocity value

	- throws:
	An error or type `PhidgetError`
	*/
	public func getMaxStallVelocity() throws -> Double {
		let result: PhidgetReturnCode
		var maxStallVelocity: Double = 0
		result = PhidgetMotorPositionController_getMaxStallVelocity(chandle, &maxStallVelocity)
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
		return maxStallVelocity
	}

	/**
	The `SurgeCurrentLimit` allows for increased performance from your motor. The controller will limit the current through your motor to the `SurgeCurrentLimit` briefly, then scale current down to the `CurrentLimit`.

	*   View `ActiveCurrentLimit` for information about what current limit the controller is actively following.

	  
	For more information about `SurgeCurrentLimit`, visit our [MotorPositionController API Guide](/docs/MotorPositionController_API_Guide#Surge_Current_Limit)

	- returns:
	The surge current limit value

	- throws:
	An error or type `PhidgetError`
	*/
	public func getSurgeCurrentLimit() throws -> Double {
		let result: PhidgetReturnCode
		var surgeCurrentLimit: Double = 0
		result = PhidgetMotorPositionController_getSurgeCurrentLimit(chandle, &surgeCurrentLimit)
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
		return surgeCurrentLimit
	}

	/**
	The `SurgeCurrentLimit` allows for increased performance from your motor. The controller will limit the current through your motor to the `SurgeCurrentLimit` briefly, then scale current down to the `CurrentLimit`.

	*   View `ActiveCurrentLimit` for information about what current limit the controller is actively following.

	  
	For more information about `SurgeCurrentLimit`, visit our [MotorPositionController API Guide](/docs/MotorPositionController_API_Guide#Surge_Current_Limit)

	- throws:
	An error or type `PhidgetError`

	- parameters:
		- surgeCurrentLimit: The surge current limit value
	*/
	public func setSurgeCurrentLimit(_ surgeCurrentLimit: Double) throws {
		let result: PhidgetReturnCode
		result = PhidgetMotorPositionController_setSurgeCurrentLimit(chandle, surgeCurrentLimit)
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
	}

	/**
	The minimum value that `SurgeCurrentLimit` can be set to.

	- returns:
	The surge current value

	- throws:
	An error or type `PhidgetError`
	*/
	public func getMinSurgeCurrentLimit() throws -> Double {
		let result: PhidgetReturnCode
		var minSurgeCurrentLimit: Double = 0
		result = PhidgetMotorPositionController_getMinSurgeCurrentLimit(chandle, &minSurgeCurrentLimit)
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
		return minSurgeCurrentLimit
	}

	/**
	The maximum value that `SurgeCurrentLimit` can be set to.

	- returns:
	The surge current value

	- throws:
	An error or type `PhidgetError`
	*/
	public func getMaxSurgeCurrentLimit() throws -> Double {
		let result: PhidgetReturnCode
		var maxSurgeCurrentLimit: Double = 0
		result = PhidgetMotorPositionController_getMaxSurgeCurrentLimit(chandle, &maxSurgeCurrentLimit)
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
		return maxSurgeCurrentLimit
	}

	/**
	When the controller is engaged and the `TargetPosition` is set, the motor will attempt to reach the `TargetPosition`.

	*   If the `DeadBand` is non-zero, the final position of the motor may not match the `TargetPosition`
	*   Use the `RescaleFactor` to convert the units of this property to more intuitive units, such as rotations or degrees.

	  
	For more information about `TargetPosition`, visit our [MotorPositionController API Guide](/docs/MotorPositionController_API_Guide#Target_Position)

	- returns:
	The position value

	- throws:
	An error or type `PhidgetError`
	*/
	public func getTargetPosition() throws -> Double {
		let result: PhidgetReturnCode
		var targetPosition: Double = 0
		result = PhidgetMotorPositionController_getTargetPosition(chandle, &targetPosition)
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
		return targetPosition
	}

	/**
	When the controller is engaged and the `TargetPosition` is set, the motor will attempt to reach the `TargetPosition`.

	*   If the `DeadBand` is non-zero, the final position of the motor may not match the `TargetPosition`
	*   Use the `RescaleFactor` to convert the units of this property to more intuitive units, such as rotations or degrees.

	  
	For more information about `TargetPosition`, visit our [MotorPositionController API Guide](/docs/MotorPositionController_API_Guide#Target_Position)

	- throws:
	An error or type `PhidgetError`

	- parameters:
		- targetPosition: The position value
	*/
	public func setTargetPosition(_ targetPosition: Double) throws {
		let result: PhidgetReturnCode
		result = PhidgetMotorPositionController_setTargetPosition(chandle, targetPosition)
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
	}

	/**
	When the controller is engaged and the `TargetPosition` is set, the motor will attempt to reach the `TargetPosition`.

	*   If the `DeadBand` is non-zero, the final position of the motor may not match the `TargetPosition`
	*   Use the `RescaleFactor` to convert the units of this property to more intuitive units, such as rotations or degrees.

	  
	For more information about `TargetPosition`, visit our [MotorPositionController API Guide](/docs/MotorPositionController_API_Guide#Target_Position)

	- parameters:
		- targetPosition: The position value
		- completion: Asynchronous completion callback
	*/
	public func setTargetPosition(_ targetPosition: Double, completion: @escaping (ErrorCode) -> ()) {
		let callback = AsyncCallback(completion)
		let callbackCtx = Unmanaged.passRetained(callback)
		PhidgetMotorPositionController_setTargetPosition_async(chandle, targetPosition, AsyncCallback.nativeAsyncCallback, UnsafeMutableRawPointer(callbackCtx.toOpaque()))
	}

	/**
	The controller will attempt to limit the motor's velocity to this value.

	*   The `VelocityLimit` may be exceeded to track the `TargetPosition` more accurately.
	*   Use the `RescaleFactor` to convert the units of this property to more intuitive units, such as rotations or degrees.

	  
	For more information about `VelocityLimit`, visit our [MotorPositionController API Guide](/docs/MotorPositionController_API_Guide#Velocity_Limit)

	- returns:
	The velocity value.

	- throws:
	An error or type `PhidgetError`
	*/
	public func getVelocityLimit() throws -> Double {
		let result: PhidgetReturnCode
		var velocityLimit: Double = 0
		result = PhidgetMotorPositionController_getVelocityLimit(chandle, &velocityLimit)
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
		return velocityLimit
	}

	/**
	The controller will attempt to limit the motor's velocity to this value.

	*   The `VelocityLimit` may be exceeded to track the `TargetPosition` more accurately.
	*   Use the `RescaleFactor` to convert the units of this property to more intuitive units, such as rotations or degrees.

	  
	For more information about `VelocityLimit`, visit our [MotorPositionController API Guide](/docs/MotorPositionController_API_Guide#Velocity_Limit)

	- throws:
	An error or type `PhidgetError`

	- parameters:
		- velocityLimit: The velocity value.
	*/
	public func setVelocityLimit(_ velocityLimit: Double) throws {
		let result: PhidgetReturnCode
		result = PhidgetMotorPositionController_setVelocityLimit(chandle, velocityLimit)
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
	}

	/**
	The minimum value that `VelocityLimit` can be set to.

	*   Use the `RescaleFactor` to convert the units of this property to more intuitive units, such as rotations or degrees.

	- returns:
	The velocity value

	- throws:
	An error or type `PhidgetError`
	*/
	public func getMinVelocityLimit() throws -> Double {
		let result: PhidgetReturnCode
		var minVelocityLimit: Double = 0
		result = PhidgetMotorPositionController_getMinVelocityLimit(chandle, &minVelocityLimit)
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
		return minVelocityLimit
	}

	/**
	The maximum value that `VelocityLimit` can be set to.

	*   Use the `RescaleFactor` to convert the units of this property to more intuitive units, such as rotations or degrees.

	- returns:
	The velocity value

	- throws:
	An error or type `PhidgetError`
	*/
	public func getMaxVelocityLimit() throws -> Double {
		let result: PhidgetReturnCode
		var maxVelocityLimit: Double = 0
		result = PhidgetMotorPositionController_getMaxVelocityLimit(chandle, &maxVelocityLimit)
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
		return maxVelocityLimit
	}

	internal override func initializeEvents() {
		initializeBaseEvents()
		PhidgetMotorPositionController_setOnDutyCycleUpdateHandler(chandle, nativeDutyCycleUpdateHandler, UnsafeMutableRawPointer(selfCtx!.toOpaque()))
		PhidgetMotorPositionController_setOnExpectedPositionChangeHandler(chandle, nativeExpectedPositionChangeHandler, UnsafeMutableRawPointer(selfCtx!.toOpaque()))
		PhidgetMotorPositionController_setOnPositionChangeHandler(chandle, nativePositionChangeHandler, UnsafeMutableRawPointer(selfCtx!.toOpaque()))
	}

	internal override func uninitializeEvents() {
		uninitializeBaseEvents()
		PhidgetMotorPositionController_setOnDutyCycleUpdateHandler(chandle, nil, nil)
		PhidgetMotorPositionController_setOnExpectedPositionChangeHandler(chandle, nil, nil)
		PhidgetMotorPositionController_setOnPositionChangeHandler(chandle, nil, nil)
	}

	/**
	The most recent duty cycle value will be reported in this event, which occurs when the `DataInterval` has elapsed.

	*   This event will **always** occur when the `DataInterval` elapses. You can depend on this event for constant timing when implementing control loops in code. This is the last event to fire, giving you up-to-date access to all properties.

	---
	## Parameters:
	*   `dutyCycle`: The duty cycle value
	*/
	public let dutyCycleUpdate = Event<MotorPositionController, Double> ()
	let nativeDutyCycleUpdateHandler : PhidgetMotorPositionController_OnDutyCycleUpdateCallback = { ch, ctx, dutyCycle in
		let me = Unmanaged<MotorPositionController>.fromOpaque(ctx!).takeUnretainedValue()
		me.dutyCycleUpdate.raise(me, dutyCycle);
	}

	/**
	The most recent position being tracked by the Position Control loop, which occurs when the `DataInterval` has elapsed.

	*   Regardless of the `DataInterval`, this event will occur only when the expected position value has changed from the previous value reported.
	*   Use the `RescaleFactor` to convert the units of this property to more intuitive units, such as rotations or degrees.

	---
	## Parameters:
	*   `expectedPosition`: The expected position value
	*/
	public let expectedPositionChange = Event<MotorPositionController, Double> ()
	let nativeExpectedPositionChangeHandler : PhidgetMotorPositionController_OnExpectedPositionChangeCallback = { ch, ctx, expectedPosition in
		let me = Unmanaged<MotorPositionController>.fromOpaque(ctx!).takeUnretainedValue()
		me.expectedPositionChange.raise(me, expectedPosition);
	}

	/**
	The most recent position value will be reported in this event, which occurs when the `DataInterval` has elapsed.

	*   Regardless of the `DataInterval`, this event will occur only when the position value has changed from the previous value reported.
	*   Use the `RescaleFactor` to convert the units of this property to more intuitive units, such as rotations or degrees.

	---
	## Parameters:
	*   `position`: The position value
	*/
	public let positionChange = Event<MotorPositionController, Double> ()
	let nativePositionChangeHandler : PhidgetMotorPositionController_OnPositionChangeCallback = { ch, ctx, position in
		let me = Unmanaged<MotorPositionController>.fromOpaque(ctx!).takeUnretainedValue()
		me.positionChange.raise(me, position);
	}

}
