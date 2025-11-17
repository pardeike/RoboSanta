import Foundation
//import Phidget22

/**
The GPS class is used to configure and gather data from Phidgets GPS sensors, and gives you access to variables from GPS data packets.
*/
public class GPS: GPSBase {

	/**
	The current UTC date and time of the GPS
	
	- returns:
	Current date and time
	
	- throws:
	An error or type `PhidgetError`
	*/
	public func getDateAndTime() throws -> Date? {
		var result: PhidgetReturnCode
		var date: PhidgetGPS_Date = PhidgetGPS_Date()
		result = PhidgetGPS_getDate(chandle, &date)
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
		var time: PhidgetGPS_Time = PhidgetGPS_Time()
		result = PhidgetGPS_getTime(chandle, &time)
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
		
		var dateComponents = DateComponents()
		dateComponents.year = Int(date.tm_year)
		dateComponents.month = Int(date.tm_mon)
		dateComponents.day = Int(date.tm_mday)
		dateComponents.timeZone = TimeZone(secondsFromGMT: 0) // UTC
		dateComponents.hour = Int(time.tm_hour)
		dateComponents.minute = Int(time.tm_min)
		dateComponents.second = Int(time.tm_sec)
		dateComponents.nanosecond = Int(time.tm_ms) * 1000000
		
		// Create date from components
		let userCalendar = Calendar.current // user calendar
		let someDateTime = userCalendar.date(from: dateComponents)
		return someDateTime
	}
}
