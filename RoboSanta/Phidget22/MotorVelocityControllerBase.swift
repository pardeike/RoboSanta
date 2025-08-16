import Foundation
//import Phidget22

/**
The Motor Velocity Controller class controls the velocity and acceleration of the attached motor. It also contains various other control and monitoring functions that aid in the control of the motor.
*/
public class MotorVelocityControllerBase : Phidget {

	public init() {
		var h: PhidgetHandle?
		PhidgetMotorVelocityController_create(&h)
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
			PhidgetMotorVelocityController_delete(&chandle)
		}
	}

	/**
	The rate at which the controller can change the motor's velocity.

	*   Use the `RescaleFactor` to convert the units of this property to more intuitive units, such as rotations or degrees.

	  
	For more information about `Acceleration`, visit our [MotorVelocityController API Guide](/docs/MotorVelocityController_API_Guide#Acceleration)

	- returns:
	The acceleration value

	- throws:
	An error or type `PhidgetError`
	*/
	public func getAcceleration() throws -> Double {
		let result: PhidgetReturnCode
		var acceleration: Double = 0
		result = PhidgetMotorVelocityController_getAcceleration(chandle, &acceleration)
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
		return acceleration
	}

	/**
	The rate at which the controller can change the motor's velocity.

	*   Use the `RescaleFactor` to convert the units of this property to more intuitive units, such as rotations or degrees.

	  
	For more information about `Acceleration`, visit our [MotorVelocityController API Guide](/docs/MotorVelocityController_API_Guide#Acceleration)

	- throws:
	An error or type `PhidgetError`

	- parameters:
		- acceleration: The acceleration value
	*/
	public func setAcceleration(_ acceleration: Double) throws {
		let result: PhidgetReturnCode
		result = PhidgetMotorVelocityController_setAcceleration(chandle, acceleration)
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
		result = PhidgetMotorVelocityController_getMinAcceleration(chandle, &minAcceleration)
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
		result = PhidgetMotorVelocityController_getMaxAcceleration(chandle, &maxAcceleration)
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
		result = PhidgetMotorVelocityController_getActiveCurrentLimit(chandle, &activeCurrentLimit)
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
		return activeCurrentLimit
	}

	/**
	The controller will limit the current through the motor to the `CurrentLimit` value.

	*   View `ActiveCurrentLimit` for information about what current limit the controller is actively following.

	  
	For more information about `CurrentLimit`, visit our [MotorVelocityController API Guide](/docs/MotorVelocityController_API_Guide#Current_Limit)

	- returns:
	Motor current limit

	- throws:
	An error or type `PhidgetError`
	*/
	public func getCurrentLimit() throws -> Double {
		let result: PhidgetReturnCode
		var currentLimit: Double = 0
		result = PhidgetMotorVelocityController_getCurrentLimit(chandle, &currentLimit)
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
		return currentLimit
	}

	/**
	The controller will limit the current through the motor to the `CurrentLimit` value.

	*   View `ActiveCurrentLimit` for information about what current limit the controller is actively following.

	  
	For more information about `CurrentLimit`, visit our [MotorVelocityController API Guide](/docs/MotorVelocityController_API_Guide#Current_Limit)

	- throws:
	An error or type `PhidgetError`

	- parameters:
		- currentLimit: Motor current limit
	*/
	public func setCurrentLimit(_ currentLimit: Double) throws {
		let result: PhidgetReturnCode
		result = PhidgetMotorVelocityController_setCurrentLimit(chandle, currentLimit)
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
		result = PhidgetMotorVelocityController_getMinCurrentLimit(chandle, &minCurrentLimit)
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
		result = PhidgetMotorVelocityController_getMaxCurrentLimit(chandle, &maxCurrentLimit)
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
		return maxCurrentLimit
	}

	/**
	The `DataInterval` is the time that must elapse before the channel will fire another `VelocityChange` / `DutyCycleUpdate` event.

	*   The data interval is bounded by `MinDataInterval` and `MaxDataInterval`.

	- returns:
	The data interval value

	- throws:
	An error or type `PhidgetError`
	*/
	public func getDataInterval() throws -> UInt32 {
		let result: PhidgetReturnCode
		var dataInterval: UInt32 = 0
		result = PhidgetMotorVelocityController_getDataInterval(chandle, &dataInterval)
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
		return dataInterval
	}

	/**
	The `DataInterval` is the time that must elapse before the channel will fire another `VelocityChange` / `DutyCycleUpdate` event.

	*   The data interval is bounded by `MinDataInterval` and `MaxDataInterval`.

	- throws:
	An error or type `PhidgetError`

	- parameters:
		- dataInterval: The data interval value
	*/
	public func setDataInterval(_ dataInterval: UInt32) throws {
		let result: PhidgetReturnCode
		result = PhidgetMotorVelocityController_setDataInterval(chandle, dataInterval)
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
		result = PhidgetMotorVelocityController_getMinDataInterval(chandle, &minDataInterval)
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
		result = PhidgetMotorVelocityController_getMaxDataInterval(chandle, &maxDataInterval)
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
		result = PhidgetMotorVelocityController_getDataRate(chandle, &dataRate)
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
		result = PhidgetMotorVelocityController_setDataRate(chandle, dataRate)
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
		result = PhidgetMotorVelocityController_getMinDataRate(chandle, &minDataRate)
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
		result = PhidgetMotorVelocityController_getMaxDataRate(chandle, &maxDataRate)
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
		return maxDataRate
	}

	/**
	This parameter specifies a minimum `Velocity` below which your system will relax if the `TargetVelocity` is set to 0, to prevent unwanted jitter.

	*   Use the `RescaleFactor` to convert the units of this property to more intuitive units, such as rotations or degrees.

	  
	For more information about `DeadBand`, visit our [MotorVelocityController API Guide](/docs/MotorVelocityController_API_Guide#Deadband)

	- returns:
	The dead band value

	- throws:
	An error or type `PhidgetError`
	*/
	public func getDeadBand() throws -> Double {
		let result: PhidgetReturnCode
		var deadBand: Double = 0
		result = PhidgetMotorVelocityController_getDeadBand(chandle, &deadBand)
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
		return deadBand
	}

	/**
	This parameter specifies a minimum `Velocity` below which your system will relax if the `TargetVelocity` is set to 0, to prevent unwanted jitter.

	*   Use the `RescaleFactor` to convert the units of this property to more intuitive units, such as rotations or degrees.

	  
	For more information about `DeadBand`, visit our [MotorVelocityController API Guide](/docs/MotorVelocityController_API_Guide#Deadband)

	- throws:
	An error or type `PhidgetError`

	- parameters:
		- deadBand: The dead band value
	*/
	public func setDeadBand(_ deadBand: Double) throws {
		let result: PhidgetReturnCode
		result = PhidgetMotorVelocityController_setDeadBand(chandle, deadBand)
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
	}

	/**
	The most recent `DutyCycle` value that the controller has reported.

	*   This value will be between -1 and 1 where a sign change (±) is indicitave of a direction change.
	*   `DutyCycle` is an indication of the average voltage across the motor. At a constant load, an increase in `DutyCycle` indicates an increase in motor speed.

	  
	For more information about `DutyCycle`, visit our [MotorVelocityController API Guide](/docs/MotorVelocityController_API_Guide#Duty_Cycle)

	- returns:
	The duty cycle value.

	- throws:
	An error or type `PhidgetError`
	*/
	public func getDutyCycle() throws -> Double {
		let result: PhidgetReturnCode
		var dutyCycle: Double = 0
		result = PhidgetMotorVelocityController_getDutyCycle(chandle, &dutyCycle)
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
		return dutyCycle
	}

	/**
	When engaged, the controller has the ability to be controlled. When disengaged, the controller will stop powering to your motor, it will instead be in a freewheel state.

	  
	For more information about `Engaged`, visit our [MotorVelocityController API Guide](/docs/MotorVelocityController_API_Guide#Engage_Motor)

	- returns:
	The engaged value.

	- throws:
	An error or type `PhidgetError`
	*/
	public func getEngaged() throws -> Bool {
		let result: PhidgetReturnCode
		var engaged: Int32 = 0
		result = PhidgetMotorVelocityController_getEngaged(chandle, &engaged)
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
		return (engaged == 0 ? false : true)
	}

	/**
	When engaged, the controller has the ability to be controlled. When disengaged, the controller will stop powering to your motor, it will instead be in a freewheel state.

	  
	For more information about `Engaged`, visit our [MotorVelocityController API Guide](/docs/MotorVelocityController_API_Guide#Engage_Motor)

	- throws:
	An error or type `PhidgetError`

	- parameters:
		- engaged: The engaged value.
	*/
	public func setEngaged(_ engaged: Bool) throws {
		let result: PhidgetReturnCode
		result = PhidgetMotorVelocityController_setEngaged(chandle, (engaged ? 1 : 0))
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
	}

	/**
	This controller uses trapezoidal motion profiling combined with a PID loop to accurately track velocity. The `ExpectedVelocity` represents the current velocity the controller is tracking along the trapezoidal motion curve. The error of your PID loop is calculated by taking the difference of `Velocity` and `ExpectedVelocity`. You can use this value to verify your controller is working as expected.

	*   Set `EnableExpectedVelocity` to **TRUE** to enable the change event for this property.
	*   Use the `RescaleFactor` to convert the units of this property to more intuitive units, such as rotations or degrees.

	- returns:
	The expected velocity value

	- throws:
	An error or type `PhidgetError`
	*/
	public func getExpectedVelocity() throws -> Double {
		let result: PhidgetReturnCode
		var expectedVelocity: Double = 0
		result = PhidgetMotorVelocityController_getExpectedVelocity(chandle, &expectedVelocity)
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
		return expectedVelocity
	}

	/**
	When enabled, the `ExpectedVelocity` will be sent back from the controller.

	- throws:
	An error or type `PhidgetError`

	- parameters:
		- enableExpectedVelocity: Enable expected velocity feedback
	*/
	public func setEnableExpectedVelocity(_ enableExpectedVelocity: Bool) throws {
		let result: PhidgetReturnCode
		result = PhidgetMotorVelocityController_setEnableExpectedVelocity(chandle, (enableExpectedVelocity ? 1 : 0))
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
	}

	/**
	When enabled, the `ExpectedVelocity` will be sent back from the controller.

	- returns:
	Enable expected velocity feedback

	- throws:
	An error or type `PhidgetError`
	*/
	public func getEnableExpectedVelocity() throws -> Bool {
		let result: PhidgetReturnCode
		var enableExpectedVelocity: Int32 = 0
		result = PhidgetMotorVelocityController_getEnableExpectedVelocity(chandle, &enableExpectedVelocity)
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
		return (enableExpectedVelocity == 0 ? false : true)
	}

	/**
	Enables the **failsafe** feature for the channel, with the specified **failsafe time**.

	Enabling the failsafe feature starts a recurring **failsafe timer** for the channel. Once the failsafe is enabled, the timer must be reset within the specified time or the channel will enter a **failsafe state**. For Motor Velocity Controller channels, this will disengage the motor. The failsafe timer can be reset by using any API call **_except_** for the following:

	*   `setRescaleFactor()`
	*   'get' API calls

	For more information about failsafe, visit our [Failsafe Guide](/docs/Failsafe_Guide).

	- throws:
	An error or type `PhidgetError`

	- parameters:
		- failsafeTime: Failsafe timeout in milliseconds
	*/
	public func enableFailsafe(failsafeTime: UInt32) throws {
		let result: PhidgetReturnCode
		result = PhidgetMotorVelocityController_enableFailsafe(chandle, failsafeTime)
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
	}

	/**
	This setting allows you to choose whether motor will forcibly stop once it enters a **FAILSAFE** state.

	*   A setting of FALSE will simply stop applying power to the motor, allowing it to spin down naturally.
	*   A setting of TRUE will apply braking up to the `FailsafeCurrentLimit`, actively stopping the motor

	  
	For more information about `FailsafeBrakingEnabled`, visit our [MotorVelocityController API Guide](/docs/MotorVelocityController_API_Guide#Failsafe_Braking_Enabled)

	- returns:
	Enables failsafe braking

	- throws:
	An error or type `PhidgetError`
	*/
	public func getFailsafeBrakingEnabled() throws -> Bool {
		let result: PhidgetReturnCode
		var failsafeBrakingEnabled: Int32 = 0
		result = PhidgetMotorVelocityController_getFailsafeBrakingEnabled(chandle, &failsafeBrakingEnabled)
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
		return (failsafeBrakingEnabled == 0 ? false : true)
	}

	/**
	This setting allows you to choose whether motor will forcibly stop once it enters a **FAILSAFE** state.

	*   A setting of FALSE will simply stop applying power to the motor, allowing it to spin down naturally.
	*   A setting of TRUE will apply braking up to the `FailsafeCurrentLimit`, actively stopping the motor

	  
	For more information about `FailsafeBrakingEnabled`, visit our [MotorVelocityController API Guide](/docs/MotorVelocityController_API_Guide#Failsafe_Braking_Enabled)

	- throws:
	An error or type `PhidgetError`

	- parameters:
		- failsafeBrakingEnabled: Enables failsafe braking
	*/
	public func setFailsafeBrakingEnabled(_ failsafeBrakingEnabled: Bool) throws {
		let result: PhidgetReturnCode
		result = PhidgetMotorVelocityController_setFailsafeBrakingEnabled(chandle, (failsafeBrakingEnabled ? 1 : 0))
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
	}

	/**
	When the controller enters a **FAILSAFE** state, the controller will limit the current through the motor to the `FailsafeCurrentLimit` value.

	  
	For more information about `FailsafeCurrentLimit`, visit our [MotorVelocityController API Guide](/docs/MotorVelocityController_API_Guide#Failsafe_Current_Limit)

	- returns:
	The failsafe current limit value

	- throws:
	An error or type `PhidgetError`
	*/
	public func getFailsafeCurrentLimit() throws -> Double {
		let result: PhidgetReturnCode
		var failsafeCurrentLimit: Double = 0
		result = PhidgetMotorVelocityController_getFailsafeCurrentLimit(chandle, &failsafeCurrentLimit)
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
		return failsafeCurrentLimit
	}

	/**
	When the controller enters a **FAILSAFE** state, the controller will limit the current through the motor to the `FailsafeCurrentLimit` value.

	  
	For more information about `FailsafeCurrentLimit`, visit our [MotorVelocityController API Guide](/docs/MotorVelocityController_API_Guide#Failsafe_Current_Limit)

	- throws:
	An error or type `PhidgetError`

	- parameters:
		- failsafeCurrentLimit: The failsafe current limit value
	*/
	public func setFailsafeCurrentLimit(_ failsafeCurrentLimit: Double) throws {
		let result: PhidgetReturnCode
		result = PhidgetMotorVelocityController_setFailsafeCurrentLimit(chandle, failsafeCurrentLimit)
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
		result = PhidgetMotorVelocityController_getMinFailsafeTime(chandle, &minFailsafeTime)
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
		result = PhidgetMotorVelocityController_getMaxFailsafeTime(chandle, &maxFailsafeTime)
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
		return maxFailsafeTime
	}

	/**
	The controller will attempt to measure the inductance of your motor when opened. This value is used to improve control of the motor.

	*   Set this value during the `Phidget.Attach` event to skip motor characterization (including the audible beeps). You can use a previously saved `Inductance` value, or information from your motor's datasheet.

	  
	For more information about `Inductance`, visit our [MotorVelocityController API Guide](/docs/MotorVelocityController_API_Guide#Motor_Inductance)

	- returns:
	The inductance of your motor

	- throws:
	An error or type `PhidgetError`
	*/
	public func getInductance() throws -> Double {
		let result: PhidgetReturnCode
		var inductance: Double = 0
		result = PhidgetMotorVelocityController_getInductance(chandle, &inductance)
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
		return inductance
	}

	/**
	The controller will attempt to measure the inductance of your motor when opened. This value is used to improve control of the motor.

	*   Set this value during the `Phidget.Attach` event to skip motor characterization (including the audible beeps). You can use a previously saved `Inductance` value, or information from your motor's datasheet.

	  
	For more information about `Inductance`, visit our [MotorVelocityController API Guide](/docs/MotorVelocityController_API_Guide#Motor_Inductance)

	- throws:
	An error or type `PhidgetError`

	- parameters:
		- inductance: The inductance of your motor
	*/
	public func setInductance(_ inductance: Double) throws {
		let result: PhidgetReturnCode
		result = PhidgetMotorVelocityController_setInductance(chandle, inductance)
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
		result = PhidgetMotorVelocityController_getMinInductance(chandle, &minInductance)
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
		result = PhidgetMotorVelocityController_getMaxInductance(chandle, &maxInductance)
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
		return maxInductance
	}

	/**
	Derivative gain constant. A higher `Kd` will help reduce oscillations.

	  
	For more information about `Kd`, visit our [MotorVelocityController API Guide](/docs/MotorVelocityController_API_Guide#Tunings_Constants_(Kp,_Ki,_Kd))

	- returns:
	The Kd value.

	- throws:
	An error or type `PhidgetError`
	*/
	public func getKd() throws -> Double {
		let result: PhidgetReturnCode
		var kd: Double = 0
		result = PhidgetMotorVelocityController_getKd(chandle, &kd)
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
		return kd
	}

	/**
	Derivative gain constant. A higher `Kd` will help reduce oscillations.

	  
	For more information about `Kd`, visit our [MotorVelocityController API Guide](/docs/MotorVelocityController_API_Guide#Tunings_Constants_(Kp,_Ki,_Kd))

	- throws:
	An error or type `PhidgetError`

	- parameters:
		- kd: The Kd value.
	*/
	public func setKd(_ kd: Double) throws {
		let result: PhidgetReturnCode
		result = PhidgetMotorVelocityController_setKd(chandle, kd)
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
	}

	/**
	Integral gain constant. The integral term will help eliminate steady-state error.

	  
	For more information about `Ki`, visit our [MotorVelocityController API Guide](/docs/MotorVelocityController_API_Guide#Tunings_Constants_(Kp,_Ki,_Kd))

	- returns:
	The Ki value.

	- throws:
	An error or type `PhidgetError`
	*/
	public func getKi() throws -> Double {
		let result: PhidgetReturnCode
		var ki: Double = 0
		result = PhidgetMotorVelocityController_getKi(chandle, &ki)
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
		return ki
	}

	/**
	Integral gain constant. The integral term will help eliminate steady-state error.

	  
	For more information about `Ki`, visit our [MotorVelocityController API Guide](/docs/MotorVelocityController_API_Guide#Tunings_Constants_(Kp,_Ki,_Kd))

	- throws:
	An error or type `PhidgetError`

	- parameters:
		- ki: The Ki value.
	*/
	public func setKi(_ ki: Double) throws {
		let result: PhidgetReturnCode
		result = PhidgetMotorVelocityController_setKi(chandle, ki)
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
	}

	/**
	Proportional gain constant. A small `Kp` value will result in a less responsive controller, however, if `Kp` is too high, the system can become unstable.

	  
	For more information about `Kp`, visit our [MotorVelocityController API Guide](/docs/MotorVelocityController_API_Guide#Tunings_Constants_(Kp,_Ki,_Kd))

	- returns:
	The Kp value.

	- throws:
	An error or type `PhidgetError`
	*/
	public func getKp() throws -> Double {
		let result: PhidgetReturnCode
		var kp: Double = 0
		result = PhidgetMotorVelocityController_getKp(chandle, &kp)
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
		return kp
	}

	/**
	Proportional gain constant. A small `Kp` value will result in a less responsive controller, however, if `Kp` is too high, the system can become unstable.

	  
	For more information about `Kp`, visit our [MotorVelocityController API Guide](/docs/MotorVelocityController_API_Guide#Tunings_Constants_(Kp,_Ki,_Kd))

	- throws:
	An error or type `PhidgetError`

	- parameters:
		- kp: The Kp value.
	*/
	public func setKp(_ kp: Double) throws {
		let result: PhidgetReturnCode
		result = PhidgetMotorVelocityController_setKp(chandle, kp)
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
	}

	/**
	Determines whether the controller uses the hall effect sensors or an encoder for velocity information. This setting is locked in once the channel is `Engaged` and cannot be changed until the channel is reset.

	- returns:
	The position type selection

	- throws:
	An error or type `PhidgetError`
	*/
	public func getPositionType() throws -> PositionType {
		let result: PhidgetReturnCode
		var positionType: Phidget_PositionType = POSITION_TYPE_ENCODER
		result = PhidgetMotorVelocityController_getPositionType(chandle, &positionType)
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
		return PositionType(rawValue: positionType.rawValue)!
	}

	/**
	Determines whether the controller uses the hall effect sensors or an encoder for velocity information. This setting is locked in once the channel is `Engaged` and cannot be changed until the channel is reset.

	- throws:
	An error or type `PhidgetError`

	- parameters:
		- positionType: The position type selection
	*/
	public func setPositionType(_ positionType: PositionType) throws {
		let result: PhidgetReturnCode
		result = PhidgetMotorVelocityController_setPositionType(chandle, Phidget_PositionType(positionType.rawValue))
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
	}

	/**
	Change the units of your parameters so that your application is more intuitive.

	*   Units for `Acceleration`, `DeadBand`, `ExpectedVelocity`, `TargetVelocity`, and `Velocity` can be set by the user through the `RescaleFactor`. The `RescaleFactor` allows you to use more intuitive units such as rotations, or degrees.

	  
	For more information about `RescaleFactor`, visit our [MotorVelocityController API Guide](/docs/MotorVelocityController_API_Guide#Rescale_Factor)

	- returns:
	The rescale factor value

	- throws:
	An error or type `PhidgetError`
	*/
	public func getRescaleFactor() throws -> Double {
		let result: PhidgetReturnCode
		var rescaleFactor: Double = 0
		result = PhidgetMotorVelocityController_getRescaleFactor(chandle, &rescaleFactor)
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
		return rescaleFactor
	}

	/**
	Change the units of your parameters so that your application is more intuitive.

	*   Units for `Acceleration`, `DeadBand`, `ExpectedVelocity`, `TargetVelocity`, and `Velocity` can be set by the user through the `RescaleFactor`. The `RescaleFactor` allows you to use more intuitive units such as rotations, or degrees.

	  
	For more information about `RescaleFactor`, visit our [MotorVelocityController API Guide](/docs/MotorVelocityController_API_Guide#Rescale_Factor)

	- throws:
	An error or type `PhidgetError`

	- parameters:
		- rescaleFactor: The rescale factor value
	*/
	public func setRescaleFactor(_ rescaleFactor: Double) throws {
		let result: PhidgetReturnCode
		result = PhidgetMotorVelocityController_setRescaleFactor(chandle, rescaleFactor)
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
		result = PhidgetMotorVelocityController_resetFailsafe(chandle)
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
		result = PhidgetMotorVelocityController_getStallVelocity(chandle, &stallVelocity)
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
		result = PhidgetMotorVelocityController_setStallVelocity(chandle, stallVelocity)
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
		result = PhidgetMotorVelocityController_getMinStallVelocity(chandle, &minStallVelocity)
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
		result = PhidgetMotorVelocityController_getMaxStallVelocity(chandle, &maxStallVelocity)
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
		return maxStallVelocity
	}

	/**
	The `SurgeCurrentLimit` allows for increased performance from your motor. The controller will limit the current through your motor to the `SurgeCurrentLimit` briefly, then scale current down to the `CurrentLimit`.

	*   View `ActiveCurrentLimit` for information about what current limit the controller is actively following.

	  
	For more information about `SurgeCurrentLimit`, visit our [MotorVelocityController API Guide](/docs/MotorVelocityController_API_Guide#Surge_Current_Limit)

	- returns:
	The surge current limit value

	- throws:
	An error or type `PhidgetError`
	*/
	public func getSurgeCurrentLimit() throws -> Double {
		let result: PhidgetReturnCode
		var surgeCurrentLimit: Double = 0
		result = PhidgetMotorVelocityController_getSurgeCurrentLimit(chandle, &surgeCurrentLimit)
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
		return surgeCurrentLimit
	}

	/**
	The `SurgeCurrentLimit` allows for increased performance from your motor. The controller will limit the current through your motor to the `SurgeCurrentLimit` briefly, then scale current down to the `CurrentLimit`.

	*   View `ActiveCurrentLimit` for information about what current limit the controller is actively following.

	  
	For more information about `SurgeCurrentLimit`, visit our [MotorVelocityController API Guide](/docs/MotorVelocityController_API_Guide#Surge_Current_Limit)

	- throws:
	An error or type `PhidgetError`

	- parameters:
		- surgeCurrentLimit: The surge current limit value
	*/
	public func setSurgeCurrentLimit(_ surgeCurrentLimit: Double) throws {
		let result: PhidgetReturnCode
		result = PhidgetMotorVelocityController_setSurgeCurrentLimit(chandle, surgeCurrentLimit)
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
		result = PhidgetMotorVelocityController_getMinSurgeCurrentLimit(chandle, &minSurgeCurrentLimit)
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
		result = PhidgetMotorVelocityController_getMaxSurgeCurrentLimit(chandle, &maxSurgeCurrentLimit)
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
		return maxSurgeCurrentLimit
	}

	/**
	When moving, the motor velocity will be limited by this value.

	*   Use the `RescaleFactor` to convert the units of this property to more intuitive units, such as rotations or degrees.

	  
	For more information about `TargetVelocity`, visit our [MotorVelocityController API Guide](/docs/MotorVelocityController_API_Guide#Target_Velocity)

	- returns:
	The velocity value.

	- throws:
	An error or type `PhidgetError`
	*/
	public func getTargetVelocity() throws -> Double {
		let result: PhidgetReturnCode
		var targetVelocity: Double = 0
		result = PhidgetMotorVelocityController_getTargetVelocity(chandle, &targetVelocity)
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
		return targetVelocity
	}

	/**
	When moving, the motor velocity will be limited by this value.

	*   Use the `RescaleFactor` to convert the units of this property to more intuitive units, such as rotations or degrees.

	  
	For more information about `TargetVelocity`, visit our [MotorVelocityController API Guide](/docs/MotorVelocityController_API_Guide#Target_Velocity)

	- throws:
	An error or type `PhidgetError`

	- parameters:
		- targetVelocity: The velocity value.
	*/
	public func setTargetVelocity(_ targetVelocity: Double) throws {
		let result: PhidgetReturnCode
		result = PhidgetMotorVelocityController_setTargetVelocity(chandle, targetVelocity)
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
	}

	/**
	The minimum value that `TargetVelocity` can be set to.

	*   Use the `RescaleFactor` to convert the units of this property to more intuitive units, such as rotations or degrees.

	- returns:
	The velocity value

	- throws:
	An error or type `PhidgetError`
	*/
	public func getMinTargetVelocity() throws -> Double {
		let result: PhidgetReturnCode
		var minTargetVelocity: Double = 0
		result = PhidgetMotorVelocityController_getMinTargetVelocity(chandle, &minTargetVelocity)
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
		return minTargetVelocity
	}

	/**
	The maximum value that `TargetVelocity` can be set to.

	*   Use the `RescaleFactor` to convert the units of this property to more intuitive units, such as rotations or degrees.

	- returns:
	The velocity value

	- throws:
	An error or type `PhidgetError`
	*/
	public func getMaxTargetVelocity() throws -> Double {
		let result: PhidgetReturnCode
		var maxTargetVelocity: Double = 0
		result = PhidgetMotorVelocityController_getMaxTargetVelocity(chandle, &maxTargetVelocity)
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
		return maxTargetVelocity
	}

	/**
	The most recent velocity value that the controller has reported.

	*   Use the `RescaleFactor` to convert the units of this property to more intuitive units, such as rotations or degrees.

	- returns:
	The velocity value

	- throws:
	An error or type `PhidgetError`
	*/
	public func getVelocity() throws -> Double {
		let result: PhidgetReturnCode
		var velocity: Double = 0
		result = PhidgetMotorVelocityController_getVelocity(chandle, &velocity)
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
		return velocity
	}

	internal override func initializeEvents() {
		initializeBaseEvents()
		PhidgetMotorVelocityController_setOnDutyCycleUpdateHandler(chandle, nativeDutyCycleUpdateHandler, UnsafeMutableRawPointer(selfCtx!.toOpaque()))
		PhidgetMotorVelocityController_setOnExpectedVelocityChangeHandler(chandle, nativeExpectedVelocityChangeHandler, UnsafeMutableRawPointer(selfCtx!.toOpaque()))
		PhidgetMotorVelocityController_setOnVelocityChangeHandler(chandle, nativeVelocityChangeHandler, UnsafeMutableRawPointer(selfCtx!.toOpaque()))
	}

	internal override func uninitializeEvents() {
		uninitializeBaseEvents()
		PhidgetMotorVelocityController_setOnDutyCycleUpdateHandler(chandle, nil, nil)
		PhidgetMotorVelocityController_setOnExpectedVelocityChangeHandler(chandle, nil, nil)
		PhidgetMotorVelocityController_setOnVelocityChangeHandler(chandle, nil, nil)
	}

	/**
	The most recent duty cycle value will be reported in this event, which occurs when the `DataInterval` has elapsed.

	*   This event will **always** occur when the `DataInterval` elapses. You can depend on this event for constant timing when implementing control loops in code. This is the last event to fire, giving you up-to-date access to all properties.

	---
	## Parameters:
	*   `dutyCycle`: The duty cycle value
	*/
	public let dutyCycleUpdate = Event<MotorVelocityController, Double> ()
	let nativeDutyCycleUpdateHandler : PhidgetMotorVelocityController_OnDutyCycleUpdateCallback = { ch, ctx, dutyCycle in
		let me = Unmanaged<MotorVelocityController>.fromOpaque(ctx!).takeUnretainedValue()
		me.dutyCycleUpdate.raise(me, dutyCycle);
	}

	/**
	The most recent velocity being tracked by the Velocity Control loop, which occurs when the `DataInterval` has elapsed.

	*   Regardless of the `DataInterval`, this event will occur only when the velocity value has changed from the previous value reported.
	*   Use the `RescaleFactor` to convert the units of this property to more intuitive units, such as rotations or degrees.

	---
	## Parameters:
	*   `expectedVelocity`: The expected velocity value
	*/
	public let expectedVelocityChange = Event<MotorVelocityController, Double> ()
	let nativeExpectedVelocityChangeHandler : PhidgetMotorVelocityController_OnExpectedVelocityChangeCallback = { ch, ctx, expectedVelocity in
		let me = Unmanaged<MotorVelocityController>.fromOpaque(ctx!).takeUnretainedValue()
		me.expectedVelocityChange.raise(me, expectedVelocity);
	}

	/**
	The most recent velocity value will be reported in this event, which occurs when the `DataInterval` has elapsed.

	*   Use the `RescaleFactor` to convert the units of this property to more intuitive units, such as rotations or degrees.

	---
	## Parameters:
	*   `velocity`: The velocity value
	*/
	public let velocityChange = Event<MotorVelocityController, Double> ()
	let nativeVelocityChangeHandler : PhidgetMotorVelocityController_OnVelocityChangeCallback = { ch, ctx, velocity in
		let me = Unmanaged<MotorVelocityController>.fromOpaque(ctx!).takeUnretainedValue()
		me.velocityChange.raise(me, velocity);
	}

}
