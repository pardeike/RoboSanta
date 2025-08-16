import Foundation
//import Phidget22

/**
The Spatial class simultaneously gathers data from the acceleromter, gyroscope and magnetometer on a Phidget board.

You can also use the individual classes for these sensors if you want to handle the data in separate events.
*/
public class SpatialBase : Phidget {

	public init() {
		var h: PhidgetHandle?
		PhidgetSpatial_create(&h)
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
			PhidgetSpatial_delete(&chandle)
		}
	}

	/**
	The minimum acceleration the sensor will measure.

	- returns:
	The minimum acceleration value

	- throws:
	An error or type `PhidgetError`
	*/
	public func getMinAcceleration() throws -> [Double] {
		let result: PhidgetReturnCode
		var minAcceleration: (Double, Double, Double) = (0, 0, 0)
		result = PhidgetSpatial_getMinAcceleration(chandle, &minAcceleration)
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
		return [minAcceleration.0, minAcceleration.1, minAcceleration.2]
	}

	/**
	The maximum acceleration the sensor will measure.

	- returns:
	The maximum acceleration values

	- throws:
	An error or type `PhidgetError`
	*/
	public func getMaxAcceleration() throws -> [Double] {
		let result: PhidgetReturnCode
		var maxAcceleration: (Double, Double, Double) = (0, 0, 0)
		result = PhidgetSpatial_getMaxAcceleration(chandle, &maxAcceleration)
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
		return [maxAcceleration.0, maxAcceleration.1, maxAcceleration.2]
	}

	/**
	Calibrate your device for the environment it will be used in.

	*   Setting these parameters will allow you to tune the AHRS algorithm on the device to your specific application.

	- throws:
	An error or type `PhidgetError`

	- parameters:
		- angularVelocityThreshold: The maximum angular velocity reading where the device is assumed to be "at rest"
		- angularVelocityDeltaThreshold: The acceptable amount of change in angular velocity between measurements before movement is assumed.
		- accelerationThreshold: The maximum acceleration applied to the device (minus gravity) where it is assumed to be "at rest". This is also the maximum acceleration allowable before the device stops correcting to the acceleration vector.
		- magTime: The time it will take to correct the heading 95% of the way to aligning with the compass (in seconds),up to 15 degrees of error. Beyond 15 degrees, this is the time it will take for the bearing to move 45 degrees towards the compass reading. Remember you can zero the algorithm at any time to instantly realign the spatial with acceleration and magnetic field vectors regardless of magnitude.
		- accelTime: The time it will take to correct the pitch and roll 95% of the way to aligning with the accelerometer (in seconds).
		- biasTime: The time it will take to have the gyro biases settle to within 95% of the measured steady state (in seconds).
	*/
	public func setAHRSParameters(angularVelocityThreshold: Double, angularVelocityDeltaThreshold: Double, accelerationThreshold: Double, magTime: Double, accelTime: Double, biasTime: Double) throws {
		let result: PhidgetReturnCode
		result = PhidgetSpatial_setAHRSParameters(chandle, angularVelocityThreshold, angularVelocityDeltaThreshold, accelerationThreshold, magTime, accelTime, biasTime)
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
	}

	/**
	Selects the IMU/AHRS algorithm.

	- returns:
	The sensor algorithm

	- throws:
	An error or type `PhidgetError`
	*/
	public func getAlgorithm() throws -> SpatialAlgorithm {
		let result: PhidgetReturnCode
		var algorithm: Phidget_SpatialAlgorithm = SPATIAL_ALGORITHM_NONE
		result = PhidgetSpatial_getAlgorithm(chandle, &algorithm)
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
		return SpatialAlgorithm(rawValue: algorithm.rawValue)!
	}

	/**
	Selects the IMU/AHRS algorithm.

	- throws:
	An error or type `PhidgetError`

	- parameters:
		- algorithm: The sensor algorithm
	*/
	public func setAlgorithm(_ algorithm: SpatialAlgorithm) throws {
		let result: PhidgetReturnCode
		result = PhidgetSpatial_setAlgorithm(chandle, Phidget_SpatialAlgorithm(algorithm.rawValue))
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
	}

	/**
	Sets the gain for the magnetometer in the AHRS algorithm. Lower gains reduce sensor noise while slowing response time.

	- returns:
	The AHRS algorithm magnetometer gain

	- throws:
	An error or type `PhidgetError`
	*/
	public func getAlgorithmMagnetometerGain() throws -> Double {
		let result: PhidgetReturnCode
		var algorithmMagnetometerGain: Double = 0
		result = PhidgetSpatial_getAlgorithmMagnetometerGain(chandle, &algorithmMagnetometerGain)
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
		return algorithmMagnetometerGain
	}

	/**
	Sets the gain for the magnetometer in the AHRS algorithm. Lower gains reduce sensor noise while slowing response time.

	- throws:
	An error or type `PhidgetError`

	- parameters:
		- algorithmMagnetometerGain: The AHRS algorithm magnetometer gain
	*/
	public func setAlgorithmMagnetometerGain(_ algorithmMagnetometerGain: Double) throws {
		let result: PhidgetReturnCode
		result = PhidgetSpatial_setAlgorithmMagnetometerGain(chandle, algorithmMagnetometerGain)
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
	}

	/**
	The minimum angular rate the sensor will measure.

	- returns:
	The angular rate values

	- throws:
	An error or type `PhidgetError`
	*/
	public func getMinAngularRate() throws -> [Double] {
		let result: PhidgetReturnCode
		var minAngularRate: (Double, Double, Double) = (0, 0, 0)
		result = PhidgetSpatial_getMinAngularRate(chandle, &minAngularRate)
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
		return [minAngularRate.0, minAngularRate.1, minAngularRate.2]
	}

	/**
	The maximum angular rate the sensor will measure.

	- returns:
	The angular rate values

	- throws:
	An error or type `PhidgetError`
	*/
	public func getMaxAngularRate() throws -> [Double] {
		let result: PhidgetReturnCode
		var maxAngularRate: (Double, Double, Double) = (0, 0, 0)
		result = PhidgetSpatial_getMaxAngularRate(chandle, &maxAngularRate)
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
		return [maxAngularRate.0, maxAngularRate.1, maxAngularRate.2]
	}

	/**
	The `DataInterval` is the time that must elapse before the channel will fire another `SpatialData` event.

	*   The data interval is bounded by `MinDataInterval` and `MaxDataInterval`.

	- returns:
	The data interval value

	- throws:
	An error or type `PhidgetError`
	*/
	public func getDataInterval() throws -> UInt32 {
		let result: PhidgetReturnCode
		var dataInterval: UInt32 = 0
		result = PhidgetSpatial_getDataInterval(chandle, &dataInterval)
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
		return dataInterval
	}

	/**
	The `DataInterval` is the time that must elapse before the channel will fire another `SpatialData` event.

	*   The data interval is bounded by `MinDataInterval` and `MaxDataInterval`.

	- throws:
	An error or type `PhidgetError`

	- parameters:
		- dataInterval: The data interval value
	*/
	public func setDataInterval(_ dataInterval: UInt32) throws {
		let result: PhidgetReturnCode
		result = PhidgetSpatial_setDataInterval(chandle, dataInterval)
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
		result = PhidgetSpatial_getMinDataInterval(chandle, &minDataInterval)
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
		result = PhidgetSpatial_getMaxDataInterval(chandle, &maxDataInterval)
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
		result = PhidgetSpatial_getDataRate(chandle, &dataRate)
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
		result = PhidgetSpatial_setDataRate(chandle, dataRate)
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
		result = PhidgetSpatial_getMinDataRate(chandle, &minDataRate)
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
		result = PhidgetSpatial_getMaxDataRate(chandle, &maxDataRate)
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
		return maxDataRate
	}

	/**
	Gets the latest device orientation in the form of Euler angles. (Pitch, roll, and yaw)

	- returns:
	Gets the latest device orientation in the form of Euler angles.

	- throws:
	An error or type `PhidgetError`
	*/
	public func getEulerAngles() throws -> SpatialEulerAngles {
		let result: PhidgetReturnCode
		var eulerAngles: PhidgetSpatial_SpatialEulerAngles = PhidgetSpatial_SpatialEulerAngles()
		result = PhidgetSpatial_getEulerAngles(chandle, &eulerAngles)
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
		return SpatialEulerAngles(eulerAngles)
	}

	/**
	Set to TRUE to enable the temperature stabilization feature of this device. This enables on-board heating elements to bring the board up to a known temperature to minimize ambient temperature effects on the sensor's reading. You can leave this setting FALSE to conserve power consumption.  
	  
	If you enable heating, it is strongly recommended to keep the board in its enclosure to keep it insulated from moving air.  
	  
	This property is shared by any and all spatial-related objects on this device (Accelerometer, Gyroscope, Magnetometer, Spatial)

	- returns:
	Whether self-heating temperature stabilization is enabled

	- throws:
	An error or type `PhidgetError`
	*/
	public func getHeatingEnabled() throws -> Bool {
		let result: PhidgetReturnCode
		var heatingEnabled: Int32 = 0
		result = PhidgetSpatial_getHeatingEnabled(chandle, &heatingEnabled)
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
		return (heatingEnabled == 0 ? false : true)
	}

	/**
	Set to TRUE to enable the temperature stabilization feature of this device. This enables on-board heating elements to bring the board up to a known temperature to minimize ambient temperature effects on the sensor's reading. You can leave this setting FALSE to conserve power consumption.  
	  
	If you enable heating, it is strongly recommended to keep the board in its enclosure to keep it insulated from moving air.  
	  
	This property is shared by any and all spatial-related objects on this device (Accelerometer, Gyroscope, Magnetometer, Spatial)

	- throws:
	An error or type `PhidgetError`

	- parameters:
		- heatingEnabled: Whether self-heating temperature stabilization is enabled
	*/
	public func setHeatingEnabled(_ heatingEnabled: Bool) throws {
		let result: PhidgetReturnCode
		result = PhidgetSpatial_setHeatingEnabled(chandle, (heatingEnabled ? 1 : 0))
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
	}

	/**
	The minimum field strength the sensor will measure.

	- returns:
	The field strength value

	- throws:
	An error or type `PhidgetError`
	*/
	public func getMinMagneticField() throws -> [Double] {
		let result: PhidgetReturnCode
		var minMagneticField: (Double, Double, Double) = (0, 0, 0)
		result = PhidgetSpatial_getMinMagneticField(chandle, &minMagneticField)
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
		return [minMagneticField.0, minMagneticField.1, minMagneticField.2]
	}

	/**
	The maximum field strength the sensor will measure.

	- returns:
	The field strength value

	- throws:
	An error or type `PhidgetError`
	*/
	public func getMaxMagneticField() throws -> [Double] {
		let result: PhidgetReturnCode
		var maxMagneticField: (Double, Double, Double) = (0, 0, 0)
		result = PhidgetSpatial_getMaxMagneticField(chandle, &maxMagneticField)
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
		return [maxMagneticField.0, maxMagneticField.1, maxMagneticField.2]
	}

	/**
	Calibrate your device for the environment it will be used in.

	*   Due to physical location, hard and soft iron offsets, and even bias errors, your device should be calibrated. We have created a calibration program that will provide you with the `MagnetometerCorrectionParameters` for your specific situation. See your device's User Guide for more information.

	- throws:
	An error or type `PhidgetError`

	- parameters:
		- magneticField: Ambient magnetic field value.
		- offset0: Provided by calibration program.
		- offset1: Provided by calibration program.
		- offset2: Provided by calibration program.
		- gain0: Provided by calibration program.
		- gain1: Provided by calibration program.
		- gain2: Provided by calibration program.
		- T0: Provided by calibration program.
		- T1: Provided by calibration program.
		- T2: Provided by calibration program.
		- T3: Provided by calibration program.
		- T4: Provided by calibration program.
		- T5: Provided by calibration program.
	*/
	public func setMagnetometerCorrectionParameters(magneticField: Double, offset0: Double, offset1: Double, offset2: Double, gain0: Double, gain1: Double, gain2: Double, T0: Double, T1: Double, T2: Double, T3: Double, T4: Double, T5: Double) throws {
		let result: PhidgetReturnCode
		result = PhidgetSpatial_setMagnetometerCorrectionParameters(chandle, magneticField, offset0, offset1, offset2, gain0, gain1, gain2, T0, T1, T2, T3, T4, T5)
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
	}

	/**
	Gets the latest AHRS/IMU quaternion sent from the device.

	- returns:
	Gets the latest AHRS/IMU quaternion sent from the device.

	- throws:
	An error or type `PhidgetError`
	*/
	public func getQuaternion() throws -> SpatialQuaternion {
		let result: PhidgetReturnCode
		var quaternion: PhidgetSpatial_SpatialQuaternion = PhidgetSpatial_SpatialQuaternion()
		result = PhidgetSpatial_getQuaternion(chandle, &quaternion)
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
		return SpatialQuaternion(quaternion)
	}

	/**
	Resets the `MagnetometerCorrectionParameters` to their default values.

	*   Due to physical location, hard and soft iron offsets, and even bias errors, your device should be calibrated. We have created a calibration program that will provide you with the `MagnetometerCorrectionParameters` for your specific situation. See your device's User Guide for more information.

	- throws:
	An error or type `PhidgetError`
	*/
	public func resetMagnetometerCorrectionParameters() throws {
		let result: PhidgetReturnCode
		result = PhidgetSpatial_resetMagnetometerCorrectionParameters(chandle)
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
	}

	/**
	Saves the `MagnetometerCorrectionParameters`.

	*   Due to physical location, hard and soft iron offsets, and even bias errors, your device should be calibrated. We have created a calibration program that will provide you with the `MagnetometerCorrectionParameters` for your specific situation. See your device's User Guide for more information.

	- throws:
	An error or type `PhidgetError`
	*/
	public func saveMagnetometerCorrectionParameters() throws {
		let result: PhidgetReturnCode
		result = PhidgetSpatial_saveMagnetometerCorrectionParameters(chandle)
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
	}

	/**
	Zeros the AHRS algorithm.

	- throws:
	An error or type `PhidgetError`
	*/
	public func zeroAlgorithm() throws {
		let result: PhidgetReturnCode
		result = PhidgetSpatial_zeroAlgorithm(chandle)
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
	}

	/**
	Re-zeros the gyroscope in 1-2 seconds.

	*   The device must be stationary when zeroing.
	*   The angular rate will be reported as 0.0°/s while zeroing.
	*   Zeroing the gyroscope is a method of compensating for the drift that is inherent to all gyroscopes. See your device's User Guide for more information on dealing with drift.

	- throws:
	An error or type `PhidgetError`
	*/
	public func zeroGyro() throws {
		let result: PhidgetReturnCode
		result = PhidgetSpatial_zeroGyro(chandle)
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
	}

	internal override func initializeEvents() {
		initializeBaseEvents()
		PhidgetSpatial_setOnAlgorithmDataHandler(chandle, nativeAlgorithmDataHandler, UnsafeMutableRawPointer(selfCtx!.toOpaque()))
		PhidgetSpatial_setOnSpatialDataHandler(chandle, nativeSpatialDataHandler, UnsafeMutableRawPointer(selfCtx!.toOpaque()))
	}

	internal override func uninitializeEvents() {
		uninitializeBaseEvents()
		PhidgetSpatial_setOnAlgorithmDataHandler(chandle, nil, nil)
		PhidgetSpatial_setOnSpatialDataHandler(chandle, nil, nil)
	}

	/**
	The most recent IMU/AHRS Quaternion will be reported in this event, which occurs when the `DataInterval` has elapsed.

	---
	## Parameters:
	*   `quaternion`: The quaternion value - \[x, y, z, w\]
	*   `timestamp`: The timestamp value
	*/
	public let algorithmData = Event<Spatial, (quaternion: [Double], timestamp: Double)> ()
	let nativeAlgorithmDataHandler : PhidgetSpatial_OnAlgorithmDataCallback = { ch, ctx, quaternion, timestamp in
		let me = Unmanaged<Spatial>.fromOpaque(ctx!).takeUnretainedValue()
		me.algorithmData.raise(me, ([Double](UnsafeBufferPointer(start: quaternion!, count: 4)), timestamp));
	}

	/**
	The most recent values that your channel has measured will be reported in this event, which occurs when the `DataInterval` has elapsed.

	---
	## Parameters:
	*   `acceleration`: The acceleration vaulues
	*   `angularRate`: The angular rate values
	*   `magneticField`: The field strength values
	*   `timestamp`: The timestamp value
	*/
	public let spatialData = Event<Spatial, (acceleration: [Double], angularRate: [Double], magneticField: [Double], timestamp: Double)> ()
	let nativeSpatialDataHandler : PhidgetSpatial_OnSpatialDataCallback = { ch, ctx, acceleration, angularRate, magneticField, timestamp in
		let me = Unmanaged<Spatial>.fromOpaque(ctx!).takeUnretainedValue()
		me.spatialData.raise(me, ([Double](UnsafeBufferPointer(start: acceleration!, count: 3)), [Double](UnsafeBufferPointer(start: angularRate!, count: 3)), [Double](UnsafeBufferPointer(start: magneticField!, count: 3)), timestamp));
	}

}
