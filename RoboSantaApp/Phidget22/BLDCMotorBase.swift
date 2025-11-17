import Foundation
//import Phidget22

/**
The BLDC Motor class controls the power applied to attached brushless DC motors to affect its speed and direction. It can also contain various other control and monitoring functions that aid in the control of brushless DC motors.
*/
public class BLDCMotorBase : Phidget {

	public init() {
		var h: PhidgetHandle?
		PhidgetBLDCMotor_create(&h)
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
			PhidgetBLDCMotor_delete(&chandle)
		}
	}

	/**
	The rate at which the controller can change the motor's `Velocity`.

	  
	For more information about `Acceleration`, visit our [BLDCMotor API Guide](/docs/BLDCMotor_API_Guide#Acceleration)

	- returns:
	The acceleration value

	- throws:
	An error or type `PhidgetError`
	*/
	public func getAcceleration() throws -> Double {
		let result: PhidgetReturnCode
		var acceleration: Double = 0
		result = PhidgetBLDCMotor_getAcceleration(chandle, &acceleration)
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
		return acceleration
	}

	/**
	The rate at which the controller can change the motor's `Velocity`.

	  
	For more information about `Acceleration`, visit our [BLDCMotor API Guide](/docs/BLDCMotor_API_Guide#Acceleration)

	- throws:
	An error or type `PhidgetError`

	- parameters:
		- acceleration: The acceleration value
	*/
	public func setAcceleration(_ acceleration: Double) throws {
		let result: PhidgetReturnCode
		result = PhidgetBLDCMotor_setAcceleration(chandle, acceleration)
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
	}

	/**
	The minimum value that `Acceleration` can be set to.

	- returns:
	The acceleration value.

	- throws:
	An error or type `PhidgetError`
	*/
	public func getMinAcceleration() throws -> Double {
		let result: PhidgetReturnCode
		var minAcceleration: Double = 0
		result = PhidgetBLDCMotor_getMinAcceleration(chandle, &minAcceleration)
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
		return minAcceleration
	}

	/**
	The maximum value that `Acceleration` can be set to.

	- returns:
	The acceleration value.

	- throws:
	An error or type `PhidgetError`
	*/
	public func getMaxAcceleration() throws -> Double {
		let result: PhidgetReturnCode
		var maxAcceleration: Double = 0
		result = PhidgetBLDCMotor_getMaxAcceleration(chandle, &maxAcceleration)
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
		return maxAcceleration
	}

	/**
	The current limit that the controller is actively following. The `SurgeCurrentLimit`, `CurrentLimit`, and temperature will impact this value.

	  
	For more information about `ActiveCurrentLimit`, visit our [BLDCMotor API Guide](/docs/BLDCMotor_API_Guide#Active_Current_Limit)

	- returns:
	The active current limit value

	- throws:
	An error or type `PhidgetError`
	*/
	public func getActiveCurrentLimit() throws -> Double {
		let result: PhidgetReturnCode
		var activeCurrentLimit: Double = 0
		result = PhidgetBLDCMotor_getActiveCurrentLimit(chandle, &activeCurrentLimit)
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
		return activeCurrentLimit
	}

	/**
	This setting allows you to choose whether the motor will resist being turned when it is not being driven forward or reverse (`Velocity` = 0).

	*   Setting `BrakingEnabled` to FALSE corresponds to free-wheeling. This means:
	    *   The motor will continue to rotate after the controller is no longer driving the motor (`Velocity` = 0), due to its momentum.
	    *   The motor shaft will provide little resistance to being turned when it is stopped.
	*   Setting `BrakingEnabled` to TRUE will engage electrical braking of the DC motor. This means:
	    *   The motor will stop more quickly if it is in motion when braking is requested.
	    *   The motor shaft will resist rotation by outside forces.
	*   Braking will be added gradually, according to the `Acceleration` setting, once the motor controller's `Velocity` reaches 0.0
	*   Braking will be immediately stopped when a new (non-zero) `TargetVelocity` is set, and the motor will accelerate to the requested velocity.
	*   Braking mode is enabled by setting the `Velocity` to 0.0

	- returns:
	Enable braking when stopped

	- throws:
	An error or type `PhidgetError`
	*/
	public func getBrakingEnabled() throws -> Bool {
		let result: PhidgetReturnCode
		var brakingEnabled: Int32 = 0
		result = PhidgetBLDCMotor_getBrakingEnabled(chandle, &brakingEnabled)
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
		return (brakingEnabled == 0 ? false : true)
	}

	/**
	This setting allows you to choose whether the motor will resist being turned when it is not being driven forward or reverse (`Velocity` = 0).

	*   Setting `BrakingEnabled` to FALSE corresponds to free-wheeling. This means:
	    *   The motor will continue to rotate after the controller is no longer driving the motor (`Velocity` = 0), due to its momentum.
	    *   The motor shaft will provide little resistance to being turned when it is stopped.
	*   Setting `BrakingEnabled` to TRUE will engage electrical braking of the DC motor. This means:
	    *   The motor will stop more quickly if it is in motion when braking is requested.
	    *   The motor shaft will resist rotation by outside forces.
	*   Braking will be added gradually, according to the `Acceleration` setting, once the motor controller's `Velocity` reaches 0.0
	*   Braking will be immediately stopped when a new (non-zero) `TargetVelocity` is set, and the motor will accelerate to the requested velocity.
	*   Braking mode is enabled by setting the `Velocity` to 0.0

	- throws:
	An error or type `PhidgetError`

	- parameters:
		- brakingEnabled: Enable braking when stopped
	*/
	public func setBrakingEnabled(_ brakingEnabled: Bool) throws {
		let result: PhidgetReturnCode
		result = PhidgetBLDCMotor_setBrakingEnabled(chandle, (brakingEnabled ? 1 : 0))
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
	}

	/**
	The most recent braking strength value that the controller has reported.

	- returns:
	The braking strength value

	- throws:
	An error or type `PhidgetError`
	*/
	public func getBrakingStrength() throws -> Double {
		let result: PhidgetReturnCode
		var brakingStrength: Double = 0
		result = PhidgetBLDCMotor_getBrakingStrength(chandle, &brakingStrength)
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
		return brakingStrength
	}

	/**
	The minimum value that `BrakingStrength` can be set to.

	- returns:
	The braking value

	- throws:
	An error or type `PhidgetError`
	*/
	public func getMinBrakingStrength() throws -> Double {
		let result: PhidgetReturnCode
		var minBrakingStrength: Double = 0
		result = PhidgetBLDCMotor_getMinBrakingStrength(chandle, &minBrakingStrength)
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
		return minBrakingStrength
	}

	/**
	The maximum value that `BrakingStrength` can be set to.

	- returns:
	The braking value

	- throws:
	An error or type `PhidgetError`
	*/
	public func getMaxBrakingStrength() throws -> Double {
		let result: PhidgetReturnCode
		var maxBrakingStrength: Double = 0
		result = PhidgetBLDCMotor_getMaxBrakingStrength(chandle, &maxBrakingStrength)
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
		return maxBrakingStrength
	}

	/**
	The controller will limit the current through the motor to the `CurrentLimit` value.

	  
	For more information about `CurrentLimit`, visit our [BLDCMotor API Guide](/docs/BLDCMotor_API_Guide#Current_Limit)

	- returns:
	The current value

	- throws:
	An error or type `PhidgetError`
	*/
	public func getCurrentLimit() throws -> Double {
		let result: PhidgetReturnCode
		var currentLimit: Double = 0
		result = PhidgetBLDCMotor_getCurrentLimit(chandle, &currentLimit)
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
		return currentLimit
	}

	/**
	The controller will limit the current through the motor to the `CurrentLimit` value.

	  
	For more information about `CurrentLimit`, visit our [BLDCMotor API Guide](/docs/BLDCMotor_API_Guide#Current_Limit)

	- throws:
	An error or type `PhidgetError`

	- parameters:
		- currentLimit: The current value
	*/
	public func setCurrentLimit(_ currentLimit: Double) throws {
		let result: PhidgetReturnCode
		result = PhidgetBLDCMotor_setCurrentLimit(chandle, currentLimit)
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
	}

	/**
	The minimum value that `CurrentLimit` can be set to.

	- returns:
	The current value

	- throws:
	An error or type `PhidgetError`
	*/
	public func getMinCurrentLimit() throws -> Double {
		let result: PhidgetReturnCode
		var minCurrentLimit: Double = 0
		result = PhidgetBLDCMotor_getMinCurrentLimit(chandle, &minCurrentLimit)
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
		return minCurrentLimit
	}

	/**
	The maximum value that `CurrentLimit` can be set to.

	- returns:
	The current value

	- throws:
	An error or type `PhidgetError`
	*/
	public func getMaxCurrentLimit() throws -> Double {
		let result: PhidgetReturnCode
		var maxCurrentLimit: Double = 0
		result = PhidgetBLDCMotor_getMaxCurrentLimit(chandle, &maxCurrentLimit)
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
		return maxCurrentLimit
	}

	/**
	The `DataInterval` is the time that must elapse before the channel will fire another `VelocityUpdate` / `PositionChange` / `BrakingStrengthChange` event.

	*   The data interval is bounded by `MinDataInterval` and `MaxDataInterval`.

	- returns:
	The data interval value

	- throws:
	An error or type `PhidgetError`
	*/
	public func getDataInterval() throws -> UInt32 {
		let result: PhidgetReturnCode
		var dataInterval: UInt32 = 0
		result = PhidgetBLDCMotor_getDataInterval(chandle, &dataInterval)
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
		return dataInterval
	}

	/**
	The `DataInterval` is the time that must elapse before the channel will fire another `VelocityUpdate` / `PositionChange` / `BrakingStrengthChange` event.

	*   The data interval is bounded by `MinDataInterval` and `MaxDataInterval`.

	- throws:
	An error or type `PhidgetError`

	- parameters:
		- dataInterval: The data interval value
	*/
	public func setDataInterval(_ dataInterval: UInt32) throws {
		let result: PhidgetReturnCode
		result = PhidgetBLDCMotor_setDataInterval(chandle, dataInterval)
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
		result = PhidgetBLDCMotor_getMinDataInterval(chandle, &minDataInterval)
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
		result = PhidgetBLDCMotor_getMaxDataInterval(chandle, &maxDataInterval)
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
		result = PhidgetBLDCMotor_getDataRate(chandle, &dataRate)
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
		result = PhidgetBLDCMotor_setDataRate(chandle, dataRate)
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
		result = PhidgetBLDCMotor_getMinDataRate(chandle, &minDataRate)
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
		result = PhidgetBLDCMotor_getMaxDataRate(chandle, &maxDataRate)
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
		return maxDataRate
	}

	/**
	This setting impacts how your motor decelerates and the amount of current that is available to your motor at any given moment.

	  
	For more information about `DriveMode`, visit our [BLDCMotor API Guide](/docs/BLDCMotor_API_Guide#Drive_Mode)

	- returns:
	The drive type selection

	- throws:
	An error or type `PhidgetError`
	*/
	public func getDriveMode() throws -> DriveMode {
		let result: PhidgetReturnCode
		var driveMode: Phidget_DriveMode = DRIVE_MODE_COAST
		result = PhidgetBLDCMotor_getDriveMode(chandle, &driveMode)
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
		return DriveMode(rawValue: driveMode.rawValue)!
	}

	/**
	This setting impacts how your motor decelerates and the amount of current that is available to your motor at any given moment.

	  
	For more information about `DriveMode`, visit our [BLDCMotor API Guide](/docs/BLDCMotor_API_Guide#Drive_Mode)

	- throws:
	An error or type `PhidgetError`

	- parameters:
		- driveMode: The drive type selection
	*/
	public func setDriveMode(_ driveMode: DriveMode) throws {
		let result: PhidgetReturnCode
		result = PhidgetBLDCMotor_setDriveMode(chandle, Phidget_DriveMode(driveMode.rawValue))
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
	}

	/**
	Enables the **failsafe** feature for the channel, with the specified **failsafe time**.

	Enabling the failsafe feature starts a recurring **failsafe timer** for the channel. Once the failsafe is enabled, the timer must be reset within the specified time or the channel will enter a **failsafe state**. For BLDC Motor channels, this will cut power to the motor, allowing it to coast (freewheel) instead. The failsafe timer can be reset by using any API call **_except_** for the following:

	*   `setRescaleFactor()`
	*   `addPositionOffset()`
	*   'get' API calls

	For more information about failsafe, visit our [Failsafe Guide](/docs/Failsafe_Guide).

	- throws:
	An error or type `PhidgetError`

	- parameters:
		- failsafeTime: Failsafe timeout in milliseconds
	*/
	public func enableFailsafe(failsafeTime: UInt32) throws {
		let result: PhidgetReturnCode
		result = PhidgetBLDCMotor_enableFailsafe(chandle, failsafeTime)
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
	}

	/**
	This setting allows you to choose whether motor will forcibly stop once it enters a **FAILSAFE** state.

	*   A setting of FALSE will simply stop applying power to the motor, allowing it to spin down naturally.
	*   A setting of TRUE will apply braking up to the `FailsafeCurrentLimit`, actively stopping the motor

	  
	For more information about `FailsafeBrakingEnabled`, visit our [BLDCMotor API Guide](/docs/BLDCMotor_API_Guide#Failsafe_Braking_Enabled)

	- returns:
	Enables failsafe braking

	- throws:
	An error or type `PhidgetError`
	*/
	public func getFailsafeBrakingEnabled() throws -> Bool {
		let result: PhidgetReturnCode
		var failsafeBrakingEnabled: Int32 = 0
		result = PhidgetBLDCMotor_getFailsafeBrakingEnabled(chandle, &failsafeBrakingEnabled)
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
		return (failsafeBrakingEnabled == 0 ? false : true)
	}

	/**
	This setting allows you to choose whether motor will forcibly stop once it enters a **FAILSAFE** state.

	*   A setting of FALSE will simply stop applying power to the motor, allowing it to spin down naturally.
	*   A setting of TRUE will apply braking up to the `FailsafeCurrentLimit`, actively stopping the motor

	  
	For more information about `FailsafeBrakingEnabled`, visit our [BLDCMotor API Guide](/docs/BLDCMotor_API_Guide#Failsafe_Braking_Enabled)

	- throws:
	An error or type `PhidgetError`

	- parameters:
		- failsafeBrakingEnabled: Enables failsafe braking
	*/
	public func setFailsafeBrakingEnabled(_ failsafeBrakingEnabled: Bool) throws {
		let result: PhidgetReturnCode
		result = PhidgetBLDCMotor_setFailsafeBrakingEnabled(chandle, (failsafeBrakingEnabled ? 1 : 0))
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
	}

	/**
	When the controller enters a **FAILSAFE** state, the controller will limit the current through the motor to the `FailsafeCurrentLimit` value.

	  
	For more information about `FailsafeCurrentLimit`, visit our [BLDCMotor API Guide](/docs/BLDCMotor_API_Guide#Failsafe_Current_Limit)

	- returns:
	The failsafe current limit value

	- throws:
	An error or type `PhidgetError`
	*/
	public func getFailsafeCurrentLimit() throws -> Double {
		let result: PhidgetReturnCode
		var failsafeCurrentLimit: Double = 0
		result = PhidgetBLDCMotor_getFailsafeCurrentLimit(chandle, &failsafeCurrentLimit)
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
		return failsafeCurrentLimit
	}

	/**
	When the controller enters a **FAILSAFE** state, the controller will limit the current through the motor to the `FailsafeCurrentLimit` value.

	  
	For more information about `FailsafeCurrentLimit`, visit our [BLDCMotor API Guide](/docs/BLDCMotor_API_Guide#Failsafe_Current_Limit)

	- throws:
	An error or type `PhidgetError`

	- parameters:
		- failsafeCurrentLimit: The failsafe current limit value
	*/
	public func setFailsafeCurrentLimit(_ failsafeCurrentLimit: Double) throws {
		let result: PhidgetReturnCode
		result = PhidgetBLDCMotor_setFailsafeCurrentLimit(chandle, failsafeCurrentLimit)
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
		result = PhidgetBLDCMotor_getMinFailsafeTime(chandle, &minFailsafeTime)
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
		result = PhidgetBLDCMotor_getMaxFailsafeTime(chandle, &maxFailsafeTime)
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
		return maxFailsafeTime
	}

	/**
	The controller will attempt to measure the inductance of your motor when opened. This value is used to improve control of the motor.

	*   Set this value during the `Phidget.Attach` event to skip motor characterization (including the audible beeps). You can use a previously saved `Inductance` value, or information from your motor's datasheet.

	  
	For more information about `Inductance`, visit our [BLDCMotor API Guide](/docs/BLDCMotor_API_Guide#Motor_Inductance)

	- returns:
	The inductance of your motor

	- throws:
	An error or type `PhidgetError`
	*/
	public func getInductance() throws -> Double {
		let result: PhidgetReturnCode
		var inductance: Double = 0
		result = PhidgetBLDCMotor_getInductance(chandle, &inductance)
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
		return inductance
	}

	/**
	The controller will attempt to measure the inductance of your motor when opened. This value is used to improve control of the motor.

	*   Set this value during the `Phidget.Attach` event to skip motor characterization (including the audible beeps). You can use a previously saved `Inductance` value, or information from your motor's datasheet.

	  
	For more information about `Inductance`, visit our [BLDCMotor API Guide](/docs/BLDCMotor_API_Guide#Motor_Inductance)

	- throws:
	An error or type `PhidgetError`

	- parameters:
		- inductance: The inductance of your motor
	*/
	public func setInductance(_ inductance: Double) throws {
		let result: PhidgetReturnCode
		result = PhidgetBLDCMotor_setInductance(chandle, inductance)
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
		result = PhidgetBLDCMotor_getMinInductance(chandle, &minInductance)
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
		result = PhidgetBLDCMotor_getMaxInductance(chandle, &maxInductance)
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
		return maxInductance
	}

	/**
	The most recent position value that the controller has reported.

	*   Position values are calculated using Hall Effect sensors mounted on the motor, therefore, the resolution of position depends on the motor you are using.
	*   Units for `Position` can be set by the user through the `RescaleFactor`. The `RescaleFactor` allows you to use more intuitive units such as rotations, or degrees. For more information on how to apply the `RescaleFactor` to your application, see your controller's User Guide.

	  
	For more information about `Position`, visit our [BLDCMotor API Guide](/docs/BLDCMotor_API_Guide#Position)

	- returns:
	The position value

	- throws:
	An error or type `PhidgetError`
	*/
	public func getPosition() throws -> Double {
		let result: PhidgetReturnCode
		var position: Double = 0
		result = PhidgetBLDCMotor_getPosition(chandle, &position)
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
		return position
	}

	/**
	The lower bound of `Position`.

	- returns:
	The position value

	- throws:
	An error or type `PhidgetError`
	*/
	public func getMinPosition() throws -> Double {
		let result: PhidgetReturnCode
		var minPosition: Double = 0
		result = PhidgetBLDCMotor_getMinPosition(chandle, &minPosition)
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
		return minPosition
	}

	/**
	The upper bound of `Position`.

	- returns:
	The position value

	- throws:
	An error or type `PhidgetError`
	*/
	public func getMaxPosition() throws -> Double {
		let result: PhidgetReturnCode
		var maxPosition: Double = 0
		result = PhidgetBLDCMotor_getMaxPosition(chandle, &maxPosition)
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
		return maxPosition
	}

	/**
	Adds an offset (positive or negative) to the current position.

	*   This can be especially useful for zeroing position.

	- throws:
	An error or type `PhidgetError`

	- parameters:
		- positionOffset: Amount to offset the position by
	*/
	public func addPositionOffset(positionOffset: Double) throws {
		let result: PhidgetReturnCode
		result = PhidgetBLDCMotor_addPositionOffset(chandle, positionOffset)
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
	}

	/**
	Change the units of your parameters so that your application is more intuitive.

	  
	For more information about `RescaleFactor`, visit our [BLDCMotor API Guide](/docs/BLDCMotor_API_Guide#Rescale_Factor)

	- returns:
	The rescale factor value

	- throws:
	An error or type `PhidgetError`
	*/
	public func getRescaleFactor() throws -> Double {
		let result: PhidgetReturnCode
		var rescaleFactor: Double = 0
		result = PhidgetBLDCMotor_getRescaleFactor(chandle, &rescaleFactor)
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
		return rescaleFactor
	}

	/**
	Change the units of your parameters so that your application is more intuitive.

	  
	For more information about `RescaleFactor`, visit our [BLDCMotor API Guide](/docs/BLDCMotor_API_Guide#Rescale_Factor)

	- throws:
	An error or type `PhidgetError`

	- parameters:
		- rescaleFactor: The rescale factor value
	*/
	public func setRescaleFactor(_ rescaleFactor: Double) throws {
		let result: PhidgetReturnCode
		result = PhidgetBLDCMotor_setRescaleFactor(chandle, rescaleFactor)
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
		result = PhidgetBLDCMotor_resetFailsafe(chandle)
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
	}

	/**
	Before reading this description, it is important to note the difference between the units of `StallVelocity` and `Velocity`.

	*   `Velocity` is a number between -1 and 1 with units of 'duty cycle'. It simply represents the average voltage across the motor.
	*   `StallVelocity` represents a real velocity (e.g. m/s, RPM, etc.) and the units are determined by the `RescaleFactor`. With a `RescaleFactor` of 1, the default units would be in commutations per second.

	If the load on your motor is large, your motor may begin rotating more slowly, or even fully stall. Depending on the voltage across your motor, this may result in a large amount of current through both the controller and the motor. In order to prevent damage in these situations, you can use the `StallVelocity` property.  
	  
	The `StallVelocity` should be set to the lowest velocity you would expect from your motor. The controller will then monitor the motor's velocity, as well as the `Velocity`, and prevent a 'dangerous stall' from occuring. If the controller detects a dangerous stall, it will immediately reduce the `Velocity` (i.e. average voltage) to 0 and an error will be reported to your program.

	*   A 'dangerous stall' will occur faster when the `Velocity` is higher (i.e. when the average voltage across the motor is higher)
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
		result = PhidgetBLDCMotor_getStallVelocity(chandle, &stallVelocity)
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
		return stallVelocity
	}

	/**
	Before reading this description, it is important to note the difference between the units of `StallVelocity` and `Velocity`.

	*   `Velocity` is a number between -1 and 1 with units of 'duty cycle'. It simply represents the average voltage across the motor.
	*   `StallVelocity` represents a real velocity (e.g. m/s, RPM, etc.) and the units are determined by the `RescaleFactor`. With a `RescaleFactor` of 1, the default units would be in commutations per second.

	If the load on your motor is large, your motor may begin rotating more slowly, or even fully stall. Depending on the voltage across your motor, this may result in a large amount of current through both the controller and the motor. In order to prevent damage in these situations, you can use the `StallVelocity` property.  
	  
	The `StallVelocity` should be set to the lowest velocity you would expect from your motor. The controller will then monitor the motor's velocity, as well as the `Velocity`, and prevent a 'dangerous stall' from occuring. If the controller detects a dangerous stall, it will immediately reduce the `Velocity` (i.e. average voltage) to 0 and an error will be reported to your program.

	*   A 'dangerous stall' will occur faster when the `Velocity` is higher (i.e. when the average voltage across the motor is higher)
	*   A 'dangerous stall' will occur faster as (`StallVelocity` \- motor velocity) becomes larger .

	Setting `StallVelocity` to 0 will turn off stall protection functionality.

	- throws:
	An error or type `PhidgetError`

	- parameters:
		- stallVelocity: The stall velocity value.
	*/
	public func setStallVelocity(_ stallVelocity: Double) throws {
		let result: PhidgetReturnCode
		result = PhidgetBLDCMotor_setStallVelocity(chandle, stallVelocity)
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
		result = PhidgetBLDCMotor_getMinStallVelocity(chandle, &minStallVelocity)
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
		result = PhidgetBLDCMotor_getMaxStallVelocity(chandle, &maxStallVelocity)
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
		return maxStallVelocity
	}

	/**
	The `SurgeCurrentLimit` allows for increased performance from your motor. The controller will limit the current through your motor to the `SurgeCurrentLimit` briefly, then scale current down to the `CurrentLimit`.

	*   View `ActiveCurrentLimit` for information about what current limit the controller is actively following.

	  
	For more information about `SurgeCurrentLimit`, visit our [BLDCMotor API Guide](/docs/BLDCMotor_API_Guide#Surge_Current_Limit)

	- returns:
	The surge current limit value

	- throws:
	An error or type `PhidgetError`
	*/
	public func getSurgeCurrentLimit() throws -> Double {
		let result: PhidgetReturnCode
		var surgeCurrentLimit: Double = 0
		result = PhidgetBLDCMotor_getSurgeCurrentLimit(chandle, &surgeCurrentLimit)
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
		return surgeCurrentLimit
	}

	/**
	The `SurgeCurrentLimit` allows for increased performance from your motor. The controller will limit the current through your motor to the `SurgeCurrentLimit` briefly, then scale current down to the `CurrentLimit`.

	*   View `ActiveCurrentLimit` for information about what current limit the controller is actively following.

	  
	For more information about `SurgeCurrentLimit`, visit our [BLDCMotor API Guide](/docs/BLDCMotor_API_Guide#Surge_Current_Limit)

	- throws:
	An error or type `PhidgetError`

	- parameters:
		- surgeCurrentLimit: The surge current limit value
	*/
	public func setSurgeCurrentLimit(_ surgeCurrentLimit: Double) throws {
		let result: PhidgetReturnCode
		result = PhidgetBLDCMotor_setSurgeCurrentLimit(chandle, surgeCurrentLimit)
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
		result = PhidgetBLDCMotor_getMinSurgeCurrentLimit(chandle, &minSurgeCurrentLimit)
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
		result = PhidgetBLDCMotor_getMaxSurgeCurrentLimit(chandle, &maxSurgeCurrentLimit)
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
		return maxSurgeCurrentLimit
	}

	/**
	When a motor is not being actively driven forward or reverse, you can choose if the motor will be allowed to freely turn, or will resist being turned.

	*   A low `TargetBrakingStrength` value corresponds to free wheeling, this will have the following effects:
	    *   The motor will continue to rotate after the controller is no longer driving the motor (i.e. `Velocity` is 0), due to inertia.
	    *   The motor shaft will provide little resistance to being turned when it is stopped.
	*   A higher `TargetBrakingStrength` value will resist being turned, this will have the following effects:
	    *   The motor will more stop more quickly if it is in motion and braking has been requested. It will fight against the rotation of the shaft.
	*   Braking mode is enabled by setting the `Velocity` to `MinVelocity`

	- returns:
	The braking value

	- throws:
	An error or type `PhidgetError`
	*/
	public func getTargetBrakingStrength() throws -> Double {
		let result: PhidgetReturnCode
		var targetBrakingStrength: Double = 0
		result = PhidgetBLDCMotor_getTargetBrakingStrength(chandle, &targetBrakingStrength)
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
		return targetBrakingStrength
	}

	/**
	When a motor is not being actively driven forward or reverse, you can choose if the motor will be allowed to freely turn, or will resist being turned.

	*   A low `TargetBrakingStrength` value corresponds to free wheeling, this will have the following effects:
	    *   The motor will continue to rotate after the controller is no longer driving the motor (i.e. `Velocity` is 0), due to inertia.
	    *   The motor shaft will provide little resistance to being turned when it is stopped.
	*   A higher `TargetBrakingStrength` value will resist being turned, this will have the following effects:
	    *   The motor will more stop more quickly if it is in motion and braking has been requested. It will fight against the rotation of the shaft.
	*   Braking mode is enabled by setting the `Velocity` to `MinVelocity`

	- throws:
	An error or type `PhidgetError`

	- parameters:
		- targetBrakingStrength: The braking value
	*/
	public func setTargetBrakingStrength(_ targetBrakingStrength: Double) throws {
		let result: PhidgetReturnCode
		result = PhidgetBLDCMotor_setTargetBrakingStrength(chandle, targetBrakingStrength)
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
	}

	/**
	The average voltage across the motor is based on the `TargetVelocity` value.

	*   At a constant load, increasing the target velocity will increase the speed of the motor.
	*   `TargetVelocity` is bounded by -`MaxVelocity` and +`MaxVelocity`, where a sign change (±) is indicative of a direction change.
	*   Setting `TargetVelocity` to `MinVelocity` will stop the motor. See `BrakingEnabled` for more information on stopping the motor.

	  
	For more information about `TargetVelocity`, visit our [BLDCMotor API Guide](/docs/BLDCMotor_API_Guide#Target_Velocity)

	- returns:
	The velocity value

	- throws:
	An error or type `PhidgetError`
	*/
	public func getTargetVelocity() throws -> Double {
		let result: PhidgetReturnCode
		var targetVelocity: Double = 0
		result = PhidgetBLDCMotor_getTargetVelocity(chandle, &targetVelocity)
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
		return targetVelocity
	}

	/**
	The average voltage across the motor is based on the `TargetVelocity` value.

	*   At a constant load, increasing the target velocity will increase the speed of the motor.
	*   `TargetVelocity` is bounded by -`MaxVelocity` and +`MaxVelocity`, where a sign change (±) is indicative of a direction change.
	*   Setting `TargetVelocity` to `MinVelocity` will stop the motor. See `BrakingEnabled` for more information on stopping the motor.

	  
	For more information about `TargetVelocity`, visit our [BLDCMotor API Guide](/docs/BLDCMotor_API_Guide#Target_Velocity)

	- throws:
	An error or type `PhidgetError`

	- parameters:
		- targetVelocity: The velocity value
	*/
	public func setTargetVelocity(_ targetVelocity: Double) throws {
		let result: PhidgetReturnCode
		result = PhidgetBLDCMotor_setTargetVelocity(chandle, targetVelocity)
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
	}

	/**
	The average voltage across the motor is based on the `TargetVelocity` value.

	*   At a constant load, increasing the target velocity will increase the speed of the motor.
	*   `TargetVelocity` is bounded by -`MaxVelocity` and +`MaxVelocity`, where a sign change (±) is indicative of a direction change.
	*   Setting `TargetVelocity` to `MinVelocity` will stop the motor. See `BrakingEnabled` for more information on stopping the motor.

	  
	For more information about `TargetVelocity`, visit our [BLDCMotor API Guide](/docs/BLDCMotor_API_Guide#Target_Velocity)

	- parameters:
		- targetVelocity: The velocity value
		- completion: Asynchronous completion callback
	*/
	public func setTargetVelocity(_ targetVelocity: Double, completion: @escaping (ErrorCode) -> ()) {
		let callback = AsyncCallback(completion)
		let callbackCtx = Unmanaged.passRetained(callback)
		PhidgetBLDCMotor_setTargetVelocity_async(chandle, targetVelocity, AsyncCallback.nativeAsyncCallback, UnsafeMutableRawPointer(callbackCtx.toOpaque()))
	}

	/**
	The most recent `Velocity` value that the controller has reported.

	  
	For more information about `Velocity`, visit our [BLDCMotor API Guide](/docs/BLDCMotor_API_Guide#Velocity)

	- returns:
	The velocity value

	- throws:
	An error or type `PhidgetError`
	*/
	public func getVelocity() throws -> Double {
		let result: PhidgetReturnCode
		var velocity: Double = 0
		result = PhidgetBLDCMotor_getVelocity(chandle, &velocity)
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
		return velocity
	}

	/**
	The minimum value that `TargetVelocity` can be set to.

	*   Set the `TargetVelocity` to `MinVelocity` to stop the motor. See `BrakingEnabled` for more information on stopping the motor.
	*   `TargetVelocity` is bounded by -`MaxVelocity` and +`MaxVelocity`, where a sign change (±) is indicative of a direction change.

	- returns:
	The velocity value

	- throws:
	An error or type `PhidgetError`
	*/
	public func getMinVelocity() throws -> Double {
		let result: PhidgetReturnCode
		var minVelocity: Double = 0
		result = PhidgetBLDCMotor_getMinVelocity(chandle, &minVelocity)
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
		return minVelocity
	}

	/**
	The maximum value that `TargetVelocity` can be set to.

	*   `TargetVelocity` is bounded by -`MaxVelocity` and +`MaxVelocity`, where a sign change (±) is indicative of a direction change.

	- returns:
	The velocity value

	- throws:
	An error or type `PhidgetError`
	*/
	public func getMaxVelocity() throws -> Double {
		let result: PhidgetReturnCode
		var maxVelocity: Double = 0
		result = PhidgetBLDCMotor_getMaxVelocity(chandle, &maxVelocity)
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
		return maxVelocity
	}

	internal override func initializeEvents() {
		initializeBaseEvents()
		PhidgetBLDCMotor_setOnBrakingStrengthChangeHandler(chandle, nativeBrakingStrengthChangeHandler, UnsafeMutableRawPointer(selfCtx!.toOpaque()))
		PhidgetBLDCMotor_setOnPositionChangeHandler(chandle, nativePositionChangeHandler, UnsafeMutableRawPointer(selfCtx!.toOpaque()))
		PhidgetBLDCMotor_setOnVelocityUpdateHandler(chandle, nativeVelocityUpdateHandler, UnsafeMutableRawPointer(selfCtx!.toOpaque()))
	}

	internal override func uninitializeEvents() {
		uninitializeBaseEvents()
		PhidgetBLDCMotor_setOnBrakingStrengthChangeHandler(chandle, nil, nil)
		PhidgetBLDCMotor_setOnPositionChangeHandler(chandle, nil, nil)
		PhidgetBLDCMotor_setOnVelocityUpdateHandler(chandle, nil, nil)
	}

	/**
	The most recent braking strength value will be reported in this event, which occurs when the `DataInterval` has elapsed.

	*   Regardless of the `DataInterval`, this event will occur only when the braking strength value has changed from the previous value reported.
	*   Braking mode is enabled by setting the `Velocity` to `MinVelocity`

	---
	## Parameters:
	*   `brakingStrength`: The braking strength value
	*/
	public let brakingStrengthChange = Event<BLDCMotor, Double> ()
	let nativeBrakingStrengthChangeHandler : PhidgetBLDCMotor_OnBrakingStrengthChangeCallback = { ch, ctx, brakingStrength in
		let me = Unmanaged<BLDCMotor>.fromOpaque(ctx!).takeUnretainedValue()
		me.brakingStrengthChange.raise(me, brakingStrength);
	}

	/**
	The most recent position value will be reported in this event, which occurs when the `DataInterval` has elapsed.

	*   Regardless of the `DataInterval`, this event will occur only when the position value has changed from the previous value reported.
	*   Position values are calculated using Hall Effect sensors mounted on the motor, therefore, the resolution of position depends on the motor you are using.
	*   Units for `Position` can be set by the user through the `RescaleFactor`. The `RescaleFactor` allows you to use more intuitive units such as rotations, or degrees. For more information on how to apply the `RescaleFactor` to your application, see your controller's User Guide.

	---
	## Parameters:
	*   `position`: The position value
	*/
	public let positionChange = Event<BLDCMotor, Double> ()
	let nativePositionChangeHandler : PhidgetBLDCMotor_OnPositionChangeCallback = { ch, ctx, position in
		let me = Unmanaged<BLDCMotor>.fromOpaque(ctx!).takeUnretainedValue()
		me.positionChange.raise(me, position);
	}

	/**
	The most recent velocity value will be reported in this event, which occurs when the `DataInterval` has elapsed.

	*   This event will **always** occur when the `DataInterval` elapses. You can depend on this event for constant timing when implementing control loops in code. This is the last event to fire, giving you up-to-date access to all properties.

	---
	## Parameters:
	*   `velocity`: The velocity value
	*/
	public let velocityUpdate = Event<BLDCMotor, Double> ()
	let nativeVelocityUpdateHandler : PhidgetBLDCMotor_OnVelocityUpdateCallback = { ch, ctx, velocity in
		let me = Unmanaged<BLDCMotor>.fromOpaque(ctx!).takeUnretainedValue()
		me.velocityUpdate.raise(me, velocity);
	}

}
