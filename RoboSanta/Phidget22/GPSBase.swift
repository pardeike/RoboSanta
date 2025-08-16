import Foundation
//import Phidget22

/**
The GPS class is used to configure and gather data from Phidgets GPS sensors, and gives you access to variables from GPS data packets.
*/
public class GPSBase : Phidget {

	public init() {
		var h: PhidgetHandle?
		PhidgetGPS_create(&h)
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
			PhidgetGPS_delete(&chandle)
		}
	}

	/**
	The altitude above mean sea level in meters.

	- returns:
	Altitude of the GPS

	- throws:
	An error or type `PhidgetError`
	*/
	public func getAltitude() throws -> Double {
		let result: PhidgetReturnCode
		var altitude: Double = 0
		result = PhidgetGPS_getAltitude(chandle, &altitude)
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
		return altitude
	}

	/**
	The UTC date of the last received position.

	- returns:
	Date of last position

	- throws:
	An error or type `PhidgetError`
	*/
	public func getDate() throws -> GPSDate {
		let result: PhidgetReturnCode
		var date: PhidgetGPS_Date = PhidgetGPS_Date()
		result = PhidgetGPS_getDate(chandle, &date)
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
		return GPSDate(date)
	}

	/**
	The current true course over ground of the GPS

	- returns:
	Heading of the GPS

	- throws:
	An error or type `PhidgetError`
	*/
	public func getHeading() throws -> Double {
		let result: PhidgetReturnCode
		var heading: Double = 0
		result = PhidgetGPS_getHeading(chandle, &heading)
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
		return heading
	}

	/**
	The latitude of the GPS in degrees

	- returns:
	Latitude of the GPS

	- throws:
	An error or type `PhidgetError`
	*/
	public func getLatitude() throws -> Double {
		let result: PhidgetReturnCode
		var latitude: Double = 0
		result = PhidgetGPS_getLatitude(chandle, &latitude)
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
		return latitude
	}

	/**
	The longitude of the GPS.

	- returns:
	Longtidue of the GPS

	- throws:
	An error or type `PhidgetError`
	*/
	public func getLongitude() throws -> Double {
		let result: PhidgetReturnCode
		var longitude: Double = 0
		result = PhidgetGPS_getLongitude(chandle, &longitude)
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
		return longitude
	}

	/**
	The NMEA data structure.

	- returns:
	NMEA Data structure

	- throws:
	An error or type `PhidgetError`
	*/
	public func getNMEAData() throws -> NMEAData {
		let result: PhidgetReturnCode
		var nMEAData: PhidgetGPS_NMEAData = PhidgetGPS_NMEAData()
		result = PhidgetGPS_getNMEAData(chandle, &nMEAData)
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
		return NMEAData(nMEAData)
	}

	/**
	The status of the position fix

	*   True if a fix is available and latitude, longitude, and altitude can be read. False if the fix is not available.

	- returns:
	Status of the position fix

	- throws:
	An error or type `PhidgetError`
	*/
	public func getPositionFixState() throws -> Bool {
		let result: PhidgetReturnCode
		var positionFixState: Int32 = 0
		result = PhidgetGPS_getPositionFixState(chandle, &positionFixState)
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
		return (positionFixState == 0 ? false : true)
	}

	/**
	The current UTC time of the GPS

	- returns:
	Current time

	- throws:
	An error or type `PhidgetError`
	*/
	public func getTime() throws -> GPSTime {
		let result: PhidgetReturnCode
		var time: PhidgetGPS_Time = PhidgetGPS_Time()
		result = PhidgetGPS_getTime(chandle, &time)
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
		return GPSTime(time)
	}

	/**
	The current speed over ground of the GPS.

	- returns:
	Velocity of the GPS

	- throws:
	An error or type `PhidgetError`
	*/
	public func getVelocity() throws -> Double {
		let result: PhidgetReturnCode
		var velocity: Double = 0
		result = PhidgetGPS_getVelocity(chandle, &velocity)
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
		return velocity
	}

	internal override func initializeEvents() {
		initializeBaseEvents()
		PhidgetGPS_setOnHeadingChangeHandler(chandle, nativeHeadingChangeHandler, UnsafeMutableRawPointer(selfCtx!.toOpaque()))
		PhidgetGPS_setOnPositionChangeHandler(chandle, nativePositionChangeHandler, UnsafeMutableRawPointer(selfCtx!.toOpaque()))
		PhidgetGPS_setOnPositionFixStateChangeHandler(chandle, nativePositionFixStateChangeHandler, UnsafeMutableRawPointer(selfCtx!.toOpaque()))
	}

	internal override func uninitializeEvents() {
		uninitializeBaseEvents()
		PhidgetGPS_setOnHeadingChangeHandler(chandle, nil, nil)
		PhidgetGPS_setOnPositionChangeHandler(chandle, nil, nil)
		PhidgetGPS_setOnPositionFixStateChangeHandler(chandle, nil, nil)
	}

	/**
	The most recent heading and velocity values will be reported in this event, which occurs when the GPS heading changes.

	---
	## Parameters:
	*   `heading`: The current heading
	*   `velocity`: The current velocity
	*/
	public let headingChange = Event<GPS, (heading: Double, velocity: Double)> ()
	let nativeHeadingChangeHandler : PhidgetGPS_OnHeadingChangeCallback = { ch, ctx, heading, velocity in
		let me = Unmanaged<GPS>.fromOpaque(ctx!).takeUnretainedValue()
		me.headingChange.raise(me, (heading, velocity));
	}

	/**
	The most recent values the channel has measured will be reported in this event, which occurs when the GPS position changes.

	---
	## Parameters:
	*   `latitude`: The current latitude
	*   `longitude`: The current longitude
	*   `altitude`: The current altitude
	*/
	public let positionChange = Event<GPS, (latitude: Double, longitude: Double, altitude: Double)> ()
	let nativePositionChangeHandler : PhidgetGPS_OnPositionChangeCallback = { ch, ctx, latitude, longitude, altitude in
		let me = Unmanaged<GPS>.fromOpaque(ctx!).takeUnretainedValue()
		me.positionChange.raise(me, (latitude, longitude, altitude));
	}

	/**
	Occurs when a position fix is obtained or lost.

	---
	## Parameters:
	*   `positionFixState`: The state of the position fix. True indicates a fix is obtained. False indicates no fix found.
	*/
	public let positionFixStateChange = Event<GPS, Bool> ()
	let nativePositionFixStateChangeHandler : PhidgetGPS_OnPositionFixStateChangeCallback = { ch, ctx, positionFixState in
		let me = Unmanaged<GPS>.fromOpaque(ctx!).takeUnretainedValue()
		me.positionFixStateChange.raise(me, (positionFixState == 0 ? false : true));
	}

}
