import Foundation
//import Phidget22

/**
The core Phidget class deals with functionality common to all Phidgets, such as opening and closing them, or setting Attach, Detach and Event handlers.

This class also is used to specity the associations between the Phidget software objects and their corresponding physical devices, and makes it possible to determine which Phidget is which in cases where it might otherwise be ambiguous.
*/
public class Phidget: PhidgetBase, CustomStringConvertible {

	/**
	Opens the Phidget channel.The specific channel to be opened can be specified by setting any of the following properties:
	
	*   DeviceSerialNumber
	*   DeviceLabel
	*   Channel
	*   ServerName
	*   IsLocal
	*   IsRemote
	*   HubPort
	*   HubSerialNumber
	*   HubLabel
	*   IsHubPortDevice
	
	Open will block until the channel is opened or a timeout occurs. A timeout value of 0 will wait forever.
	
	- throws:
	An error or type `PhidgetError`
	
	- parameters:
	- timeout: Timeout in milliseconds
	*/
	public override func open(timeout: UInt32) throws {
		if (retained) {
			initializeEvents()
			retained = false
		}
		try super.open(timeout: timeout)
	}
	
	/**
	Opens the Phidget channel. The specific channel to be opened can be specified by setting any of the following properties:
	
	*   DeviceSerialNumber
	*   DeviceLabel
	*   Channel
	*   ServerName
	*   IsLocal
	*   IsRemote
	*   HubPort
	*   HubSerialNumber
	*   HubLabel
	*   IsHubPortDevice
	
	Open will return immediately, with the open proceding asynchronously.Use the Attach event or Attached property to determine when the channel is ready to use.
	
	- throws:
	An error or type `PhidgetError`
	*/
	public override func open() throws {
		if (retained) {
			initializeEvents()
			retained = false
		}
		try super.open()
	}
	
	public var description: String {
		
		let str: UnsafeMutablePointer<CChar> = UnsafeMutablePointer<CChar>.allocate(capacity: 256)
		let strLen: Int = 256
		
		do {
			if (try getIsChannel()) {
				channelInfo(chandle, str, UInt32(strLen))
				return String(cString: str)
			} else {
				deviceInfo(chandle, str, UInt32(strLen))
				return String(cString: str)
			}
		} catch {
			return "Phidget Object"
		}
	}
}
