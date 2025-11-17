import Foundation
//import Phidget22

/**
The Stepper class powers and controls the stepper motor connected to the Phidget controller, allowing you to change the position, velocity, acceleration, and current limit.
*/
public class StepperBase : Phidget {

	public init() {
		var h: PhidgetHandle?
		PhidgetStepper_create(&h)
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
			PhidgetStepper_delete(&chandle)
		}
	}

	/**
	The rate at which the controller can change the motor's `Velocity`.

	*   Use the `RescaleFactor` to convert the units of this property into more intuitive units such as rotations or degrees.

	  
	For more information about `Acceleration`, visit our [Stepper API Guide](/docs/Stepper_API_Guide#Acceleration).

	- returns:
	The acceleration value

	- throws:
	An error or type `PhidgetError`
	*/
	public func getAcceleration() throws -> Double {
		let result: PhidgetReturnCode
		var acceleration: Double = 0
		result = PhidgetStepper_getAcceleration(chandle, &acceleration)
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
		return acceleration
	}

	/**
	The rate at which the controller can change the motor's `Velocity`.

	*   Use the `RescaleFactor` to convert the units of this property into more intuitive units such as rotations or degrees.

	  
	For more information about `Acceleration`, visit our [Stepper API Guide](/docs/Stepper_API_Guide#Acceleration).

	- throws:
	An error or type `PhidgetError`

	- parameters:
		- acceleration: The acceleration value
	*/
	public func setAcceleration(_ acceleration: Double) throws {
		let result: PhidgetReturnCode
		result = PhidgetStepper_setAcceleration(chandle, acceleration)
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
	}

	/**
	The minimum value that `Acceleration` can be set to.

	- returns:
	The acceleration value

	- throws:
	An error or type `PhidgetError`
	*/
	public func getMinAcceleration() throws -> Double {
		let result: PhidgetReturnCode
		var minAcceleration: Double = 0
		result = PhidgetStepper_getMinAcceleration(chandle, &minAcceleration)
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
		return minAcceleration
	}

	/**
	The maximum value that `Acceleration` can be set to.

	- returns:
	The acceleration value

	- throws:
	An error or type `PhidgetError`
	*/
	public func getMaxAcceleration() throws -> Double {
		let result: PhidgetReturnCode
		var maxAcceleration: Double = 0
		result = PhidgetStepper_getMaxAcceleration(chandle, &maxAcceleration)
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
		return maxAcceleration
	}

	/**
	This setting changes how the controller moves your motor.

	*   In `StepperControlMode.step`, a `TargetPosition` is specified and the controller moves the motor toward the target.
	*   In `StepperControlMode.run`, the controller continuously rotates the motor in a direction that is specified by the a `VelocityLimit`.

	  
	For more information about `ControlMode`, visit our [Stepper API Guide](/docs/Stepper_API_Guide#Control_Mode).

	- returns:
	The control mode value

	- throws:
	An error or type `PhidgetError`
	*/
	public func getControlMode() throws -> StepperControlMode {
		let result: PhidgetReturnCode
		var controlMode: PhidgetStepper_ControlMode = CONTROL_MODE_STEP
		result = PhidgetStepper_getControlMode(chandle, &controlMode)
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
		return StepperControlMode(rawValue: controlMode.rawValue)!
	}

	/**
	This setting changes how the controller moves your motor.

	*   In `StepperControlMode.step`, a `TargetPosition` is specified and the controller moves the motor toward the target.
	*   In `StepperControlMode.run`, the controller continuously rotates the motor in a direction that is specified by the a `VelocityLimit`.

	  
	For more information about `ControlMode`, visit our [Stepper API Guide](/docs/Stepper_API_Guide#Control_Mode).

	- throws:
	An error or type `PhidgetError`

	- parameters:
		- controlMode: The control mode value
	*/
	public func setControlMode(_ controlMode: StepperControlMode) throws {
		let result: PhidgetReturnCode
		result = PhidgetStepper_setControlMode(chandle, PhidgetStepper_ControlMode(controlMode.rawValue))
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
	}

	/**
	The current through the motor will be limited by the `CurrentLimit`.

	  
	For more information about `CurrentLimit`, visit our [Stepper API Guide](/docs/Stepper_API_Guide#Current_Limit).

	- returns:
	The current limit value

	- throws:
	An error or type `PhidgetError`
	*/
	public func getCurrentLimit() throws -> Double {
		let result: PhidgetReturnCode
		var currentLimit: Double = 0
		result = PhidgetStepper_getCurrentLimit(chandle, &currentLimit)
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
		return currentLimit
	}

	/**
	The current through the motor will be limited by the `CurrentLimit`.

	  
	For more information about `CurrentLimit`, visit our [Stepper API Guide](/docs/Stepper_API_Guide#Current_Limit).

	- throws:
	An error or type `PhidgetError`

	- parameters:
		- currentLimit: The current limit value
	*/
	public func setCurrentLimit(_ currentLimit: Double) throws {
		let result: PhidgetReturnCode
		result = PhidgetStepper_setCurrentLimit(chandle, currentLimit)
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
	}

	/**
	The minimum value that `CurrentLimit` and `HoldingCurrentLimit` can be set to.

	- returns:
	The current limit

	- throws:
	An error or type `PhidgetError`
	*/
	public func getMinCurrentLimit() throws -> Double {
		let result: PhidgetReturnCode
		var minCurrentLimit: Double = 0
		result = PhidgetStepper_getMinCurrentLimit(chandle, &minCurrentLimit)
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
		return minCurrentLimit
	}

	/**
	The maximum value that `CurrentLimit` and `HoldingCurrentLimit` can be set to.

	- returns:
	The current limit

	- throws:
	An error or type `PhidgetError`
	*/
	public func getMaxCurrentLimit() throws -> Double {
		let result: PhidgetReturnCode
		var maxCurrentLimit: Double = 0
		result = PhidgetStepper_getMaxCurrentLimit(chandle, &maxCurrentLimit)
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
		return maxCurrentLimit
	}

	/**
	The `DataInterval` is the time that must elapse before the channel will fire another `PositionChange` / `VelocityChange` event.

	*   The data interval is bounded by `MinDataInterval` and `MaxDataInterval`.

	- returns:
	The data interval value

	- throws:
	An error or type `PhidgetError`
	*/
	public func getDataInterval() throws -> UInt32 {
		let result: PhidgetReturnCode
		var dataInterval: UInt32 = 0
		result = PhidgetStepper_getDataInterval(chandle, &dataInterval)
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
		return dataInterval
	}

	/**
	The `DataInterval` is the time that must elapse before the channel will fire another `PositionChange` / `VelocityChange` event.

	*   The data interval is bounded by `MinDataInterval` and `MaxDataInterval`.

	- throws:
	An error or type `PhidgetError`

	- parameters:
		- dataInterval: The data interval value
	*/
	public func setDataInterval(_ dataInterval: UInt32) throws {
		let result: PhidgetReturnCode
		result = PhidgetStepper_setDataInterval(chandle, dataInterval)
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
		result = PhidgetStepper_getMinDataInterval(chandle, &minDataInterval)
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
		result = PhidgetStepper_getMaxDataInterval(chandle, &maxDataInterval)
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
		result = PhidgetStepper_getDataRate(chandle, &dataRate)
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
		result = PhidgetStepper_setDataRate(chandle, dataRate)
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
		result = PhidgetStepper_getMinDataRate(chandle, &minDataRate)
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
		result = PhidgetStepper_getMaxDataRate(chandle, &maxDataRate)
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
		return maxDataRate
	}

	/**
	The controller must be engaged in order to move the motor.

	*   In `StepperControlMode.step`, a `TargetPosition` must be defined or the controller will remain disengaged.

	*   In `StepperControlMode.run`, the controller will activate immediately after engage has been set to TRUE.

	  
	For more information about `Engaged`, visit our [Stepper API Guide](/docs/Stepper_API_Guide#Engage/Disengage).

	- returns:
	The engaged state

	- throws:
	An error or type `PhidgetError`
	*/
	public func getEngaged() throws -> Bool {
		let result: PhidgetReturnCode
		var engaged: Int32 = 0
		result = PhidgetStepper_getEngaged(chandle, &engaged)
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
		return (engaged == 0 ? false : true)
	}

	/**
	The controller must be engaged in order to move the motor.

	*   In `StepperControlMode.step`, a `TargetPosition` must be defined or the controller will remain disengaged.

	*   In `StepperControlMode.run`, the controller will activate immediately after engage has been set to TRUE.

	  
	For more information about `Engaged`, visit our [Stepper API Guide](/docs/Stepper_API_Guide#Engage/Disengage).

	- throws:
	An error or type `PhidgetError`

	- parameters:
		- engaged: The engaged state
	*/
	public func setEngaged(_ engaged: Bool) throws {
		let result: PhidgetReturnCode
		result = PhidgetStepper_setEngaged(chandle, (engaged ? 1 : 0))
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
	}

	/**
	Enables the **failsafe** feature for the channel, with the specified **failsafe time**.

	Enabling the failsafe feature starts a recurring **failsafe timer** for the channel. Once the failsafe is enabled, the timer must be reset within the specified time or the channel will enter a **failsafe state**. For Stepper Motor channels, this will disengage the motor. The failsafe timer can be reset by using any of the following API calls:

	*   `setAcceleration()`
	*   `setControlMode()`
	*   `setCurrentLimit()`
	*   `setDataInterval()`
	*   `setDataRate()`
	*   `setEngaged()`
	*   `setHoldingCurrentLimit()`
	*   `setVelocityLimit()`
	*   `resetFailsafe()`

	For more information about failsafe, visit our [Failsafe Guide](/docs/Failsafe_Guide).

	- throws:
	An error or type `PhidgetError`

	- parameters:
		- failsafeTime: Failsafe timeout in milliseconds
	*/
	public func enableFailsafe(failsafeTime: UInt32) throws {
		let result: PhidgetReturnCode
		result = PhidgetStepper_enableFailsafe(chandle, failsafeTime)
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
		result = PhidgetStepper_getMinFailsafeTime(chandle, &minFailsafeTime)
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
		result = PhidgetStepper_getMaxFailsafeTime(chandle, &maxFailsafeTime)
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
		return maxFailsafeTime
	}

	/**
	The current through the motor will be limited by the `HoldingCurrentLimit` while `IsMoving` is FALSE and `Engaged` is TRUE. If no `HoldingCurrentLimit` is specified, the current through the motor will be limited by the `CurrentLimit` instead.

	  
	For more information about `HoldingCurrentLimit`, visit our [Stepper API Guide](/docs/Stepper_API_Guide#Holding_Current_Limit).

	- returns:
	The current value

	- throws:
	An error or type `PhidgetError`
	*/
	public func getHoldingCurrentLimit() throws -> Double {
		let result: PhidgetReturnCode
		var holdingCurrentLimit: Double = 0
		result = PhidgetStepper_getHoldingCurrentLimit(chandle, &holdingCurrentLimit)
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
		return holdingCurrentLimit
	}

	/**
	The current through the motor will be limited by the `HoldingCurrentLimit` while `IsMoving` is FALSE and `Engaged` is TRUE. If no `HoldingCurrentLimit` is specified, the current through the motor will be limited by the `CurrentLimit` instead.

	  
	For more information about `HoldingCurrentLimit`, visit our [Stepper API Guide](/docs/Stepper_API_Guide#Holding_Current_Limit).

	- throws:
	An error or type `PhidgetError`

	- parameters:
		- holdingCurrentLimit: The current value
	*/
	public func setHoldingCurrentLimit(_ holdingCurrentLimit: Double) throws {
		let result: PhidgetReturnCode
		result = PhidgetStepper_setHoldingCurrentLimit(chandle, holdingCurrentLimit)
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
	}

	/**
	`IsMoving` returns TRUE while the controller is moving the motor.

	*   The controller receives no feedback from the motor, so this may not always reflect reality.

	  
	For more information about `IsMoving`, visit our [Stepper API Guide](/docs/Stepper_API_Guide#isMoving).

	- returns:
	The moving state

	- throws:
	An error or type `PhidgetError`
	*/
	public func getIsMoving() throws -> Bool {
		let result: PhidgetReturnCode
		var isMoving: Int32 = 0
		result = PhidgetStepper_getIsMoving(chandle, &isMoving)
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
		return (isMoving == 0 ? false : true)
	}

	/**
	The most recent Position value reported by the controller.

	*   Use the `RescaleFactor` to convert the units of this property into more intuitive units such as rotations or degrees.

	  
	For more information about `Position`, visit our [Stepper API Guide](/docs/Stepper_API_Guide#Motor_Position).

	- returns:
	The position value

	- throws:
	An error or type `PhidgetError`
	*/
	public func getPosition() throws -> Double {
		let result: PhidgetReturnCode
		var position: Double = 0
		result = PhidgetStepper_getPosition(chandle, &position)
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
		return position
	}

	/**
	The minimum value that `TargetPosition` can be set to.

	- returns:
	The position value

	- throws:
	An error or type `PhidgetError`
	*/
	public func getMinPosition() throws -> Double {
		let result: PhidgetReturnCode
		var minPosition: Double = 0
		result = PhidgetStepper_getMinPosition(chandle, &minPosition)
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
		return minPosition
	}

	/**
	The maximum value that `TargetPosition` can be set to.

	- returns:
	The position value

	- throws:
	An error or type `PhidgetError`
	*/
	public func getMaxPosition() throws -> Double {
		let result: PhidgetReturnCode
		var maxPosition: Double = 0
		result = PhidgetStepper_getMaxPosition(chandle, &maxPosition)
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
		return maxPosition
	}

	/**
	Adds an offset (positive or negative) to the current position and target position.

	*   This is especially useful for zeroing position.

	- throws:
	An error or type `PhidgetError`

	- parameters:
		- positionOffset: Amount to offset the position by
	*/
	public func addPositionOffset(positionOffset: Double) throws {
		let result: PhidgetReturnCode
		result = PhidgetStepper_addPositionOffset(chandle, positionOffset)
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
	}

	/**
	Change the units of your parameters so that your application is more intuitive

	*   View the Specifications tab of your stepper controller to see the default units. Most controllers have default units of 1/16 steps per count.

	  
	For more information about `RescaleFactor`, visit our [Stepper API Guide](/docs/Stepper_API_Guide#Rescale_Factor).

	- returns:
	The rescale factor value

	- throws:
	An error or type `PhidgetError`
	*/
	public func getRescaleFactor() throws -> Double {
		let result: PhidgetReturnCode
		var rescaleFactor: Double = 0
		result = PhidgetStepper_getRescaleFactor(chandle, &rescaleFactor)
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
		return rescaleFactor
	}

	/**
	Change the units of your parameters so that your application is more intuitive

	*   View the Specifications tab of your stepper controller to see the default units. Most controllers have default units of 1/16 steps per count.

	  
	For more information about `RescaleFactor`, visit our [Stepper API Guide](/docs/Stepper_API_Guide#Rescale_Factor).

	- throws:
	An error or type `PhidgetError`

	- parameters:
		- rescaleFactor: The rescale factor value
	*/
	public func setRescaleFactor(_ rescaleFactor: Double) throws {
		let result: PhidgetReturnCode
		result = PhidgetStepper_setRescaleFactor(chandle, rescaleFactor)
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
		result = PhidgetStepper_resetFailsafe(chandle)
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
	}

	/**
	The controller will move the motor toward the `TargetPosition` when `Engaged` is TRUE.

	*   `TargetPosition` is only used when `StepperControlMode.step` is selected.
	*   Use the `RescaleFactor` to convert the units of this property into more intuitive units such as rotations or degrees.

	  
	For more information about `TargetPosition`, visit our [Stepper API Guide](/docs/Stepper_API_Guide#Target_Position).

	- returns:
	The position value

	- throws:
	An error or type `PhidgetError`
	*/
	public func getTargetPosition() throws -> Double {
		let result: PhidgetReturnCode
		var targetPosition: Double = 0
		result = PhidgetStepper_getTargetPosition(chandle, &targetPosition)
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
		return targetPosition
	}

	/**
	The controller will move the motor toward the `TargetPosition` when `Engaged` is TRUE.

	*   `TargetPosition` is only used when `StepperControlMode.step` is selected.
	*   Use the `RescaleFactor` to convert the units of this property into more intuitive units such as rotations or degrees.

	  
	For more information about `TargetPosition`, visit our [Stepper API Guide](/docs/Stepper_API_Guide#Target_Position).

	- throws:
	An error or type `PhidgetError`

	- parameters:
		- targetPosition: The position value
	*/
	public func setTargetPosition(_ targetPosition: Double) throws {
		let result: PhidgetReturnCode
		result = PhidgetStepper_setTargetPosition(chandle, targetPosition)
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
	}

	/**
	The controller will move the motor toward the `TargetPosition` when `Engaged` is TRUE.

	*   `TargetPosition` is only used when `StepperControlMode.step` is selected.
	*   Use the `RescaleFactor` to convert the units of this property into more intuitive units such as rotations or degrees.

	  
	For more information about `TargetPosition`, visit our [Stepper API Guide](/docs/Stepper_API_Guide#Target_Position).

	- parameters:
		- targetPosition: The position value
		- completion: Asynchronous completion callback
	*/
	public func setTargetPosition(_ targetPosition: Double, completion: @escaping (ErrorCode) -> ()) {
		let callback = AsyncCallback(completion)
		let callbackCtx = Unmanaged.passRetained(callback)
		PhidgetStepper_setTargetPosition_async(chandle, targetPosition, AsyncCallback.nativeAsyncCallback, UnsafeMutableRawPointer(callbackCtx.toOpaque()))
	}

	/**
	The most recent velocity value that the controller has reported.

	*   Use the `RescaleFactor` to convert the units of this property into more intuitive units such as rotations or degrees.

	  
	For more information about `Velocity`, visit our [Stepper API Guide](/docs/Stepper_API_Guide#Motor_Velocity).

	- returns:
	The velocity value

	- throws:
	An error or type `PhidgetError`
	*/
	public func getVelocity() throws -> Double {
		let result: PhidgetReturnCode
		var velocity: Double = 0
		result = PhidgetStepper_getVelocity(chandle, &velocity)
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
		return velocity
	}

	/**
	The controller will limit the motor's velocity to this value.

	*   When `StepperControlMode.step` is selected, the `MinVelocityLimit` has a value of 0. This is because the sign (±) of the `TargetPosition` will indicate the direction.
	*   When in `StepperControlMode.run`, the `MinVelocityLimit` has a value of -1 * `MaxVelocityLimit`. This is because there is no `TargetPosition`, so the direction is defined by the sign (±) of the `VelocityLimit`.
	*   While `VelocityLimit` is listed as a double, it is rounded down to an integer number of 1/16th steps when sent to the board since the board is limited by a minimum unit of 1/16th steps/s. This is especially important to consider when using different `RescaleFactor` values where converting to units of, for example, RPM results in 1.5RPM (80 1/16th steps/s) and 1.509375 RPM (80.5 1/16th steps/s) both being sent to the board as 80 1/16th steps/s.
	*   Use the `RescaleFactor` to convert the units of this property into more intuitive units such as rotations or degrees.

	- returns:
	Velocity limit

	- throws:
	An error or type `PhidgetError`
	*/
	public func getVelocityLimit() throws -> Double {
		let result: PhidgetReturnCode
		var velocityLimit: Double = 0
		result = PhidgetStepper_getVelocityLimit(chandle, &velocityLimit)
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
		return velocityLimit
	}

	/**
	The controller will limit the motor's velocity to this value.

	*   When `StepperControlMode.step` is selected, the `MinVelocityLimit` has a value of 0. This is because the sign (±) of the `TargetPosition` will indicate the direction.
	*   When in `StepperControlMode.run`, the `MinVelocityLimit` has a value of -1 * `MaxVelocityLimit`. This is because there is no `TargetPosition`, so the direction is defined by the sign (±) of the `VelocityLimit`.
	*   While `VelocityLimit` is listed as a double, it is rounded down to an integer number of 1/16th steps when sent to the board since the board is limited by a minimum unit of 1/16th steps/s. This is especially important to consider when using different `RescaleFactor` values where converting to units of, for example, RPM results in 1.5RPM (80 1/16th steps/s) and 1.509375 RPM (80.5 1/16th steps/s) both being sent to the board as 80 1/16th steps/s.
	*   Use the `RescaleFactor` to convert the units of this property into more intuitive units such as rotations or degrees.

	- throws:
	An error or type `PhidgetError`

	- parameters:
		- velocityLimit: Velocity limit
	*/
	public func setVelocityLimit(_ velocityLimit: Double) throws {
		let result: PhidgetReturnCode
		result = PhidgetStepper_setVelocityLimit(chandle, velocityLimit)
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
	}

	/**
	The minimum value that `VelocityLimit` can be set to.

	- returns:
	The velocity limit value

	- throws:
	An error or type `PhidgetError`
	*/
	public func getMinVelocityLimit() throws -> Double {
		let result: PhidgetReturnCode
		var minVelocityLimit: Double = 0
		result = PhidgetStepper_getMinVelocityLimit(chandle, &minVelocityLimit)
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
		return minVelocityLimit
	}

	/**
	The maximum value that `VelocityLimit` can be set to.

	- returns:
	The velocity value

	- throws:
	An error or type `PhidgetError`
	*/
	public func getMaxVelocityLimit() throws -> Double {
		let result: PhidgetReturnCode
		var maxVelocityLimit: Double = 0
		result = PhidgetStepper_getMaxVelocityLimit(chandle, &maxVelocityLimit)
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
		return maxVelocityLimit
	}

	internal override func initializeEvents() {
		initializeBaseEvents()
		PhidgetStepper_setOnPositionChangeHandler(chandle, nativePositionChangeHandler, UnsafeMutableRawPointer(selfCtx!.toOpaque()))
		PhidgetStepper_setOnStoppedHandler(chandle, nativeStoppedHandler, UnsafeMutableRawPointer(selfCtx!.toOpaque()))
		PhidgetStepper_setOnVelocityChangeHandler(chandle, nativeVelocityChangeHandler, UnsafeMutableRawPointer(selfCtx!.toOpaque()))
	}

	internal override func uninitializeEvents() {
		uninitializeBaseEvents()
		PhidgetStepper_setOnPositionChangeHandler(chandle, nil, nil)
		PhidgetStepper_setOnStoppedHandler(chandle, nil, nil)
		PhidgetStepper_setOnVelocityChangeHandler(chandle, nil, nil)
	}

	/**
	The most recent position value will be reported in this event, which occurs when the `DataInterval` has elapsed.

	*   Use the `RescaleFactor` to convert the units of this property into more intuitive units such as rotations or degrees.

	---
	## Parameters:
	*   `position`: The current stepper position
	*/
	public let positionChange = Event<Stepper, Double> ()
	let nativePositionChangeHandler : PhidgetStepper_OnPositionChangeCallback = { ch, ctx, position in
		let me = Unmanaged<Stepper>.fromOpaque(ctx!).takeUnretainedValue()
		me.positionChange.raise(me, position);
	}

	/**
	Occurs when the controller stops moving the motor.

	*   The controller receives no feedback from the motor, so this may not always reflect reality.
	*/
	public let stopped = SimpleEvent<Stepper> ()
	let nativeStoppedHandler : PhidgetStepper_OnStoppedCallback = { ch, ctx in
		let me = Unmanaged<Stepper>.fromOpaque(ctx!).takeUnretainedValue()
		me.stopped.raise(me);
	}

	/**
	The most recent velocity value will be reported in this event, which occurs when the `DataInterval` has elapsed.

	*   Use the `RescaleFactor` to convert the units of this property into more intuitive units such as rotations or degrees.

	---
	## Parameters:
	*   `velocity`: Velocity of the stepper. Sign indicates direction.
	*/
	public let velocityChange = Event<Stepper, Double> ()
	let nativeVelocityChangeHandler : PhidgetStepper_OnVelocityChangeCallback = { ch, ctx, velocity in
		let me = Unmanaged<Stepper>.fromOpaque(ctx!).takeUnretainedValue()
		me.velocityChange.raise(me, velocity);
	}

}
