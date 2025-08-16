import Foundation
//import Phidget22

/**
The core Phidget class deals with functionality common to all Phidgets, such as opening and closing them, or setting Attach, Detach, Error event handlers.

This class is also used to specify the associations between the Phidget software objects and their corresponding physical devices, and makes it possible to determine which Phidget is which in cases where it might otherwise be ambiguous.

This class contains various functions such as **Release**, **Retain**, and **getParent** designed to be used with the **Phidget Manager**. These specialized functions may be safely ignored if your application does not require a **Manager**. You can check the **Manager API** for more information.
*/
public class PhidgetBase {

	var chandle: PhidgetHandle?
	var retained: Bool = false
	var selfCtx: Unmanaged<PhidgetBase>?

	init(_ handle: PhidgetHandle) {
		chandle = handle
		selfCtx = Unmanaged.passUnretained(self)
	}

	deinit {
		if (retained) {
			Phidget_release(&chandle)
		}
	}

	/**
	Pass to `setDeviceSerialNumber()` to open any serial number.
	*/
	public static let anySerialNumber: Int = -1
	/**
	Pass to `setHubPort()` to open any hub port.
	*/
	public static let anyHubPort: Int = -1
	/**
	Pass to `setChannel()` to open any channel.
	*/
	public static let anyChannel: Int = -1
	/**
	Pass to `setDeviceLabel()` to open any label.
	*/
	public static let anyLabel: String? = nil
	/**
	Pass to `open()` for an infinite timeout.
	*/
	public static let infiniteTimeout: UInt32 = 0
	/**
	Pass to `open()` for the default timeout.
	*/
	public static let defaultTimeout: UInt32 = 1000
	/**
	Pass to `setHubPortSpeed()` to set the Hub Port speed automatically when supported by both the hub port and the VINT device.
	*/
	public static let autoHubPortSpeed: Int = 0

	/**
	Release memory and threads used by the Phidget library. Should be called prior to unloading the library from the address space.

	This function is intended for use in special cases where it is desired for the Phidget library to be unloaded before a program's termination. All other API calls are unsafe after calling this.

	- throws:
	An error or type `PhidgetError`

	- parameters:
		- flags: Reserved for future use. Pass 0.
	*/
	public static func finalize(flags: Int = 0) throws {
		let result: PhidgetReturnCode
		result = Phidget_finalize(Int32(flags))
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
	}

	/**
	Gets the version of the Phidget library being used by the program in human readable form.

	- returns:
	The Phidget library version.

	- throws:
	An error or type `PhidgetError`
	*/
	public static func getLibraryVersion() throws -> String {
		let result: PhidgetReturnCode
		var libraryVersion: UnsafePointer<CChar>?
		result = Phidget_getLibraryVersion(&libraryVersion)
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
		return String(cString: libraryVersion!)
	}

	/**
	Gets the version of the Phidget library being used by the program as a version number string.

	- returns:
	The Phidget library version number.

	- throws:
	An error or type `PhidgetError`
	*/
	public static func getLibraryVersionNumber() throws -> String {
		let result: PhidgetReturnCode
		var libraryVersionNumber: UnsafePointer<CChar>?
		result = Phidget_getLibraryVersionNumber(&libraryVersionNumber)
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
		return String(cString: libraryVersionNumber!)
	}

	/**
	Closes all channels, and stops all threads. The library is reset to a newly loaded state. All channel handles have been freed.

	This function is intended for use in special cases where the library cannot be unloaded between program runs, such as LabVIEW and Unity Editor.

	- throws:
	An error or type `PhidgetError`
	*/
	public static func resetLibrary() throws {
		let result: PhidgetReturnCode
		result = Phidget_resetLibrary()
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
	}

	/**
	Gets the attached status of channel. A Phidget is attached after it has been opened and the Phidget library finds and connects to the corresponding hardware device.

	*   Most API calls are only valid on attached Phidgets.

	- returns:
	True if the channel is attached

	- throws:
	An error or type `PhidgetError`
	*/
	public func getAttached() throws -> Bool {
		let result: PhidgetReturnCode
		var attached: Int32 = 0
		result = Phidget_getAttached(chandle, &attached)
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
		return (attached == 0 ? false : true)
	}

	/**
	Gets the channel index of the channel on the device.

	- returns:
	The channel index

	- throws:
	An error or type `PhidgetError`
	*/
	public func getChannel() throws -> Int {
		let result: PhidgetReturnCode
		var channel: Int32 = 0
		result = Phidget_getChannel(chandle, &channel)
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
		return Int(channel)
	}

	/**
	Specifies the channel index to be opened. The default channel is 0. Set to `anyChannel` to open any channel on the specified device.  
	  
	If setting this property, it must be set before the channel is opened. The behaviour of setting this property while the channel is open is undefined.

	- throws:
	An error or type `PhidgetError`

	- parameters:
		- channel: The channel index
	*/
	public func setChannel(_ channel: Int) throws {
		let result: PhidgetReturnCode
		result = Phidget_setChannel(chandle, Int32(channel))
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
	}

	/**
	Gets the channel class of the channel.

	- returns:
	The channel class

	- throws:
	An error or type `PhidgetError`
	*/
	public func getChannelClass() throws -> ChannelClass {
		let result: PhidgetReturnCode
		var channelClass: Phidget_ChannelClass = PHIDCHCLASS_NOTHING
		result = Phidget_getChannelClass(chandle, &channelClass)
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
		return ChannelClass(rawValue: channelClass.rawValue)!
	}

	/**
	Gets the name of the channel class the channel belongs to.

	- returns:
	The name of the channel's class

	- throws:
	An error or type `PhidgetError`
	*/
	public func getChannelClassName() throws -> String {
		let result: PhidgetReturnCode
		var channelClassName: UnsafePointer<CChar>?
		result = Phidget_getChannelClassName(chandle, &channelClassName)
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
		return String(cString: channelClassName!)
	}

	/**
	Gets the channel's name. This name serves as a description of the specific nature of the channel.

	- returns:
	The channel's name

	- throws:
	An error or type `PhidgetError`
	*/
	public func getChannelName() throws -> String {
		let result: PhidgetReturnCode
		var channelName: UnsafePointer<CChar>?
		result = Phidget_getChannelName(chandle, &channelName)
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
		return String(cString: channelName!)
	}

	/**
	Gets the subclass for this channel. Allows for identifying channels with specific characteristics without needing to know the exact device and channel index.

	- returns:
	The channel's subclass

	- throws:
	An error or type `PhidgetError`
	*/
	public func getChannelSubclass() throws -> ChannelSubclass {
		let result: PhidgetReturnCode
		var channelSubclass: Phidget_ChannelSubclass = PHIDCHSUBCLASS_NONE
		result = Phidget_getChannelSubclass(chandle, &channelSubclass)
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
		return ChannelSubclass(rawValue: channelSubclass.rawValue)!
	}

	/**
	Closes a Phidget channel that has been opened.`close()` will release the channel on the Phidget device.

	- throws:
	An error or type `PhidgetError`
	*/
	public func close() throws {
		let result: PhidgetReturnCode
		result = Phidget_close(chandle)
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
	}

	/**
	Gets the number of channels of the specified channel class on the device. Pass `ChannelClass.none` to get the total number of channels.

	- returns:
	The Channel Count

	- throws:
	An error or type `PhidgetError`

	- parameters:
		- cls: The Channel Class
	*/
	public func getDeviceChannelCount(cls: ChannelClass) throws -> UInt32 {
		let result: PhidgetReturnCode
		var count: UInt32 = 0
		result = Phidget_getDeviceChannelCount(chandle, Phidget_ChannelClass(cls.rawValue), &count)
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
		return count
	}

	/**
	Gets the device class for the Phidget which this channel is a part of.

	- returns:
	The class of the device the channel is a part of.

	- throws:
	An error or type `PhidgetError`
	*/
	public func getDeviceClass() throws -> DeviceClass {
		let result: PhidgetReturnCode
		var deviceClass: Phidget_DeviceClass = PHIDCLASS_NOTHING
		result = Phidget_getDeviceClass(chandle, &deviceClass)
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
		return DeviceClass(rawValue: deviceClass.rawValue)!
	}

	/**
	Gets the name of the device class for the Phidget which this channel is a part of.

	- returns:
	The class name of the device the channel is a part of.

	- throws:
	An error or type `PhidgetError`
	*/
	public func getDeviceClassName() throws -> String {
		let result: PhidgetReturnCode
		var deviceClassName: UnsafePointer<CChar>?
		result = Phidget_getDeviceClassName(chandle, &deviceClassName)
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
		return String(cString: deviceClassName!)
	}

	/**
	Gets the Device ID for the Phidget which this channel is a part of.

	- returns:
	The device id of the device the channel is a part of

	- throws:
	An error or type `PhidgetError`
	*/
	public func getDeviceID() throws -> DeviceID {
		let result: PhidgetReturnCode
		var deviceID: Phidget_DeviceID = PHIDID_NOTHING
		result = Phidget_getDeviceID(chandle, &deviceID)
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
		return DeviceID(rawValue: deviceID.rawValue)!
	}

	/**
	Gets the label of the Phidget which this channel is a part of. A device label is a custom string used to more easily identify a Phidget. Labels are written to a Phidget using `writeDeviceLabel()`, or by right-clicking the device and setting a label in the Phidget Control Panel for Windows.

	- returns:
	The device label

	- throws:
	An error or type `PhidgetError`
	*/
	public func getDeviceLabel() throws -> String {
		let result: PhidgetReturnCode
		var deviceLabel: UnsafePointer<CChar>?
		result = Phidget_getDeviceLabel(chandle, &deviceLabel)
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
		return String(cString: deviceLabel!)
	}

	/**
	Specifies the label of the Phidget to be opened. Leave un-set to open any label. A device label is a custom string used to more easily identify a Phidget. Labels are written to a Phidget using `writeDeviceLabel()`, or by right-clicking the device and setting a label in the Phidget Control Panel for Windows.  
	  
	If setting this property, it must be set before the channel is opened. The behaviour of setting this property while the channel is open is undefined.

	- throws:
	An error or type `PhidgetError`

	- parameters:
		- deviceLabel: The device label
	*/
	public func setDeviceLabel(_ deviceLabel: String?) throws {
		let result: PhidgetReturnCode
		result = Phidget_setDeviceLabel(chandle, deviceLabel)
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
	}

	/**
	Gets the name of the Phidget which this channel is a part of.

	- returns:
	The name of the device the channel is a part of

	- throws:
	An error or type `PhidgetError`
	*/
	public func getDeviceName() throws -> String {
		let result: PhidgetReturnCode
		var deviceName: UnsafePointer<CChar>?
		result = Phidget_getDeviceName(chandle, &deviceName)
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
		return String(cString: deviceName!)
	}

	/**
	Gets the serial number of the Phidget which this channel is a part of.  
	If the channel is part of a VINT device, this will be the serial number of the VINT Hub the device is attached to.

	- returns:
	The device serial number

	- throws:
	An error or type `PhidgetError`
	*/
	public func getDeviceSerialNumber() throws -> Int {
		let result: PhidgetReturnCode
		var deviceSerialNumber: Int32 = 0
		result = Phidget_getDeviceSerialNumber(chandle, &deviceSerialNumber)
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
		return Int(deviceSerialNumber)
	}

	/**
	Specifies the serial number of the Phidget to be opened. Leave un-set, or set to `anySerialNumber` to open any serial number.  
	If the channel is part of a VINT device, this will be the serial number of the VINT Hub the device is attached to.  
	  
	If setting this property, it must be set before the channel is opened. The behaviour of setting this property while the channel is open is undefined.

	- throws:
	An error or type `PhidgetError`

	- parameters:
		- deviceSerialNumber: The device serial number
	*/
	public func setDeviceSerialNumber(_ deviceSerialNumber: Int) throws {
		let result: PhidgetReturnCode
		result = Phidget_setDeviceSerialNumber(chandle, Int32(deviceSerialNumber))
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
	}

	/**
	Gets the SKU (part number) of the Phidget which this channel is a part of.

	- returns:
	The SKU of the device the channel is a part of

	- throws:
	An error or type `PhidgetError`
	*/
	public func getDeviceSKU() throws -> String {
		let result: PhidgetReturnCode
		var deviceSKU: UnsafePointer<CChar>?
		result = Phidget_getDeviceSKU(chandle, &deviceSKU)
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
		return String(cString: deviceSKU!)
	}

	/**
	Gets the firmware version of the Phidget which this channel is a part of.

	- returns:
	The version of the device the channel is a part of

	- throws:
	An error or type `PhidgetError`
	*/
	public func getDeviceVersion() throws -> Int {
		let result: PhidgetReturnCode
		var deviceVersion: Int32 = 0
		result = Phidget_getDeviceVersion(chandle, &deviceVersion)
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
		return Int(deviceVersion)
	}

	/**
	Gets the hub that this channel is attached to.

	- returns:
	The hub the channels device is attached to

	- throws:
	An error or type `PhidgetError`
	*/
	public func getHub() throws -> Phidget {
		let result: PhidgetReturnCode
		var hub: PhidgetHandle?
		result = Phidget_getHub(chandle, &hub)
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
		return Manager.createRetainedTypedPhidget(hub!)
	}

	/**
	Gets the hub port index of the VINT Hub port that the channel is attached to.

	- returns:
	The hub port index

	- throws:
	An error or type `PhidgetError`
	*/
	public func getHubPort() throws -> Int {
		let result: PhidgetReturnCode
		var hubPort: Int32 = 0
		result = Phidget_getHubPort(chandle, &hubPort)
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
		return Int(hubPort)
	}

	/**
	Specifies the hub port index of the VINT Hub port to open this channel on. Leave un-set, or set to `anyHubPort` to open the channel on any VINT Hub port  
	  
	If setting this property, it must be set before the channel is opened. The behaviour of setting this property while the channel is open is undefined.

	- throws:
	An error or type `PhidgetError`

	- parameters:
		- hubPort: The hub port index
	*/
	public func setHubPort(_ hubPort: Int) throws {
		let result: PhidgetReturnCode
		result = Phidget_setHubPort(chandle, Int32(hubPort))
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
	}

	/**
	Gets the number of VINT ports present on the VINT Hub that the channel is attached to.

	- returns:
	The number of ports on the VINT Hub

	- throws:
	An error or type `PhidgetError`
	*/
	public func getHubPortCount() throws -> Int {
		let result: PhidgetReturnCode
		var hubPortCount: Int32 = 0
		result = Phidget_getHubPortCount(chandle, &hubPortCount)
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
		return Int(hubPortCount)
	}

	/**
	Configures the communication speed for this VINT device. Both the `HubPortSupportsSetSpeed` and `VINTDeviceSupportsSetSpeed` must be true in order to set the hub port speed.Available speeds are: 100000, 160000, 250000, 400000, 500000, 800000 and 1000000. Setting any other speed will select the nearest lower supported speed. The upper speed is bound by the lesser of `MaxHubPortSpeed` and `MaxVINTDeviceSpeed`. Set the speed to `autoHubPortSpeed` to enable Auto Set Speed on Hubs that support it (enabled by default).

	- returns:
	The VINT Device communication speed

	- throws:
	An error or type `PhidgetError`
	*/
	public func getHubPortSpeed() throws -> UInt32 {
		let result: PhidgetReturnCode
		var hubPortSpeed: UInt32 = 0
		result = Phidget_getHubPortSpeed(chandle, &hubPortSpeed)
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
		return hubPortSpeed
	}

	/**
	Configures the communication speed for this VINT device. Both the `HubPortSupportsSetSpeed` and `VINTDeviceSupportsSetSpeed` must be true in order to set the hub port speed.Available speeds are: 100000, 160000, 250000, 400000, 500000, 800000 and 1000000. Setting any other speed will select the nearest lower supported speed. The upper speed is bound by the lesser of `MaxHubPortSpeed` and `MaxVINTDeviceSpeed`. Set the speed to `autoHubPortSpeed` to enable Auto Set Speed on Hubs that support it (enabled by default).

	- throws:
	An error or type `PhidgetError`

	- parameters:
		- hubPortSpeed: The VINT Device communication speed
	*/
	public func setHubPortSpeed(_ hubPortSpeed: UInt32) throws {
		let result: PhidgetReturnCode
		result = Phidget_setHubPortSpeed(chandle, hubPortSpeed)
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
	}

	/**
	The max communication speed of a high-speed capable VINT Port.

	- returns:
	The VINT Port max speed

	- throws:
	An error or type `PhidgetError`
	*/
	public func getMaxHubPortSpeed() throws -> UInt32 {
		let result: PhidgetReturnCode
		var maxHubPortSpeed: UInt32 = 0
		result = Phidget_getMaxHubPortSpeed(chandle, &maxHubPortSpeed)
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
		return maxHubPortSpeed
	}

	/**
	Indicates that the communication speed of this VINT port can be set automatically.

	- returns:
	The VINT Port supports auto set speed

	- throws:
	An error or type `PhidgetError`
	*/
	public func getHubPortSupportsAutoSetSpeed() throws -> Bool {
		let result: PhidgetReturnCode
		var hubPortSupportsAutoSetSpeed: Int32 = 0
		result = Phidget_getHubPortSupportsAutoSetSpeed(chandle, &hubPortSupportsAutoSetSpeed)
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
		return (hubPortSupportsAutoSetSpeed == 0 ? false : true)
	}

	/**
	Indicates that the communication speed of this VINT port can be set.

	- returns:
	The VINT Port supports set speed

	- throws:
	An error or type `PhidgetError`
	*/
	public func getHubPortSupportsSetSpeed() throws -> Bool {
		let result: PhidgetReturnCode
		var hubPortSupportsSetSpeed: Int32 = 0
		result = Phidget_getHubPortSupportsSetSpeed(chandle, &hubPortSupportsSetSpeed)
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
		return (hubPortSupportsSetSpeed == 0 ? false : true)
	}

	/**
	Returns true if this represents a channel, false if this represents a device. Mostly for use alongside `getParent()` to distinguish channel handles from device handles.

	- returns:
	True if the handle is for a channel.

	- throws:
	An error or type `PhidgetError`
	*/
	public func getIsChannel() throws -> Bool {
		let result: PhidgetReturnCode
		var isChannel: Int32 = 0
		result = Phidget_getIsChannel(chandle, &isChannel)
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
		return (isChannel == 0 ? false : true)
	}

	/**
	Gets whether this channel is a VINT Hub port channel, or part of a VINT device attached to a hub port.

	- returns:
	The hub port mode (True if the channel is a hub port itself)

	- throws:
	An error or type `PhidgetError`
	*/
	public func getIsHubPortDevice() throws -> Bool {
		let result: PhidgetReturnCode
		var isHubPortDevice: Int32 = 0
		result = Phidget_getIsHubPortDevice(chandle, &isHubPortDevice)
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
		return (isHubPortDevice == 0 ? false : true)
	}

	/**
	Specifies whether this channel should be opened on a VINT Hub port directly, or on a VINT device attached to a hub port.  
	  
	If setting this property, it must be set before the channel is opened. The behaviour of setting this property while the channel is open is undefined.

	- throws:
	An error or type `PhidgetError`

	- parameters:
		- isHubPortDevice: The hub port mode (True if the channel is a hub port itself)
	*/
	public func setIsHubPortDevice(_ isHubPortDevice: Bool) throws {
		let result: PhidgetReturnCode
		result = Phidget_setIsHubPortDevice(chandle, (isHubPortDevice ? 1 : 0))
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
	}

	/**
	Returns true when this channel is attached directly on the local machine, or false otherwise.

	- returns:
	True if the channel is attached to a local device

	- throws:
	An error or type `PhidgetError`
	*/
	public func getIsLocal() throws -> Bool {
		let result: PhidgetReturnCode
		var isLocal: Int32 = 0
		result = Phidget_getIsLocal(chandle, &isLocal)
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
		return (isLocal == 0 ? false : true)
	}

	/**
	Set to True if the channel is to be opened locally, and not over a network. If both this and `IsRemote` are set to False (the default), the channel will be opened either locally or remotely, on whichever matching channel is found first.  
	  
	If setting this property, it must be set before the channel is opened. The behaviour of setting this property while the channel is open is undefined.

	- throws:
	An error or type `PhidgetError`

	- parameters:
		- isLocal: True if the channel is attached to a local device
	*/
	public func setIsLocal(_ isLocal: Bool) throws {
		let result: PhidgetReturnCode
		result = Phidget_setIsLocal(chandle, (isLocal ? 1 : 0))
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
	}

	/**
	Returns true if `open()` has been called on this channel.

	- returns:
	True if the channel is opened.

	- throws:
	An error or type `PhidgetError`
	*/
	public func getIsOpen() throws -> Bool {
		let result: PhidgetReturnCode
		var isOpen: Int32 = 0
		result = Phidget_getIsOpen(chandle, &isOpen)
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
		return (isOpen == 0 ? false : true)
	}

	/**
	Returns true when this channel is attached via a Phidget network server, or false otherwise.

	- returns:
	True if the channel is attached to a network device

	- throws:
	An error or type `PhidgetError`
	*/
	public func getIsRemote() throws -> Bool {
		let result: PhidgetReturnCode
		var isRemote: Int32 = 0
		result = Phidget_getIsRemote(chandle, &isRemote)
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
		return (isRemote == 0 ? false : true)
	}

	/**
	Set to True if the channel is to be opened remotely, rather than locally. If both this and `IsLocal` are set to False (the default), the channel will be opened either locally or remotely, on whichever matching channel is found first.

	In order for your program to have access to remote Phidgets, you must use the **Networking API** to `Net.enableServerDiscovery()` or `Net.addServer()`.

	If setting this property, it must be set before the channel is opened. The behaviour of setting this property while the channel is open is undefined.

	- throws:
	An error or type `PhidgetError`

	- parameters:
		- isRemote: True if the channel is attached to a network device
	*/
	public func setIsRemote(_ isRemote: Bool) throws {
		let result: PhidgetReturnCode
		result = Phidget_setIsRemote(chandle, (isRemote ? 1 : 0))
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
	}

	/**
	Opens the Phidget channel. The specific channel to be opened can be specified by setting any of the following properties:

	*   DeviceSerialNumber
	*   DeviceLabel
	*   Channel
	*   HubPort
	*   IsHubPortDevice
	*   ServerName
	*   IsLocal
	*   IsRemote

	`open()` will return immediately, with the attachment process proceeding asynchronously. Use the Attach event or Attached property to determine when the channel is ready to use.

	- throws:
	An error or type `PhidgetError`
	*/
	public func open() throws {
		let result: PhidgetReturnCode
		result = Phidget_open(chandle)
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
	}

	/**
	Opens the Phidget channel and waits a defined amount of time for the device to attach.The specific channel to be opened can be specified by setting any of the following properties:

	*   DeviceSerialNumber
	*   DeviceLabel
	*   Channel
	*   HubPort
	*   IsHubPortDevice
	*   ServerName
	*   IsLocal
	*   IsRemote

	`open()` will block until the channel is attached or a timeout occurs. A timeout value of 0 will wait forever.

	- throws:
	An error or type `PhidgetError`

	- parameters:
		- timeout: Timeout in milliseconds
	*/
	public func open(timeout: UInt32) throws {
		let result: PhidgetReturnCode
		result = Phidget_openWaitForAttachment(chandle, timeout)
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
	}

	/**
	Gets the handle of the parent device of the given Phidget handle.

	For example, this would refer to the device the channel is a part of, or the Hub that a device is plugged into.

	This is useful when used alongside a **Phidget Manager** to create device trees like the one in the Phidget Control Panel.

	*   This can be used to travel up the device tree and get device information at each step.
	*   The root device will return a null handle
	*   Parent handles always refer to devices. See `getIsChannel()`

	- returns:
	The handle of the parent

	- throws:
	An error or type `PhidgetError`
	*/
	public func getParent() throws -> Phidget? {
		let result: PhidgetReturnCode
		var parent: PhidgetHandle?
		result = Phidget_getParent(chandle, &parent)
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
		if parent == nil { return nil }
		return Manager.createRetainedTypedPhidget(parent!)
	}

	/**
	Gets the hostname of the Phidget network server for network attached Phidgets.  
	Fails if the channel is not connected to a Phidget network server.

	- returns:
	The hostname of the channel's server

	- throws:
	An error or type `PhidgetError`
	*/
	public func getServerHostname() throws -> String {
		let result: PhidgetReturnCode
		var serverHostname: UnsafePointer<CChar>?
		result = Phidget_getServerHostname(chandle, &serverHostname)
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
		return String(cString: serverHostname!)
	}

	/**
	Gets the name of the Phidget network server the channel is attached to, if any.  
	Fails if the channel is not connected to a Phidget network server.

	- returns:
	The name of the Phidget network server the channel is from

	- throws:
	An error or type `PhidgetError`
	*/
	public func getServerName() throws -> String {
		let result: PhidgetReturnCode
		var serverName: UnsafePointer<CChar>?
		result = Phidget_getServerName(chandle, &serverName)
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
		return String(cString: serverName!)
	}

	/**
	Specifies that this channel will be opened remotely, on a Phidget network server with this name.

	This function should only be used if you want your Phidget to be found on a specific server, and does not need to be specified if the Phidget can be on any any available server.

	In order for your program to have access to remote Phidgets, you must use the **Networking API** to `Net.enableServerDiscovery()` or `Net.addServer()`.

	If setting this property, it must be set before the channel is opened. The behaviour of setting this property while the channel is open is undefined.

	- throws:
	An error or type `PhidgetError`

	- parameters:
		- serverName: The name of the Phidget network server the channel is from
	*/
	public func setServerName(_ serverName: String) throws {
		let result: PhidgetReturnCode
		result = Phidget_setServerName(chandle, serverName)
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
	}

	/**
	Gets the peer name (address and port) of the Phidget server for network attached Phidgets, formatted as: `address:port`  
	Fails if the channel is not connected to a Phidget network server.

	- returns:
	The address and port of the channel's server

	- throws:
	An error or type `PhidgetError`
	*/
	public func getServerPeerName() throws -> String {
		let result: PhidgetReturnCode
		var serverPeerName: UnsafePointer<CChar>?
		result = Phidget_getServerPeerName(chandle, &serverPeerName)
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
		return String(cString: serverPeerName!)
	}

	/**
	Gets the unique name for the server the channel is attached to, if any. This is either a unique mDNS name, or the name specified in `Net.addServer()`  
	Fails if the channel is not connected to a Phidget network server.

	- returns:
	The unique name of the server

	- throws:
	An error or type `PhidgetError`
	*/
	public func getServerUniqueName() throws -> String {
		let result: PhidgetReturnCode
		var serverUniqueName: UnsafePointer<CChar>?
		result = Phidget_getServerUniqueName(chandle, &serverUniqueName)
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
		return String(cString: serverUniqueName!)
	}

	/**
	The max communication speed of a high-speed capable VINT Device.

	- returns:
	The VINT Device max commuinication speed

	- throws:
	An error or type `PhidgetError`
	*/
	public func getMaxVINTDeviceSpeed() throws -> UInt32 {
		let result: PhidgetReturnCode
		var maxVINTDeviceSpeed: UInt32 = 0
		result = Phidget_getMaxVINTDeviceSpeed(chandle, &maxVINTDeviceSpeed)
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
		return maxVINTDeviceSpeed
	}

	/**
	Indicates that the communication speed of this VINT device can be set automatically.

	- returns:
	The VINT Device supports auto set speed

	- throws:
	An error or type `PhidgetError`
	*/
	public func getVINTDeviceSupportsAutoSetSpeed() throws -> Bool {
		let result: PhidgetReturnCode
		var vINTDeviceSupportsAutoSetSpeed: Int32 = 0
		result = Phidget_getVINTDeviceSupportsAutoSetSpeed(chandle, &vINTDeviceSupportsAutoSetSpeed)
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
		return (vINTDeviceSupportsAutoSetSpeed == 0 ? false : true)
	}

	/**
	Indicates that the communication speed of this VINT device can be set.

	- returns:
	The VINT Device supports set speed

	- throws:
	An error or type `PhidgetError`
	*/
	public func getVINTDeviceSupportsSetSpeed() throws -> Bool {
		let result: PhidgetReturnCode
		var vINTDeviceSupportsSetSpeed: Int32 = 0
		result = Phidget_getVINTDeviceSupportsSetSpeed(chandle, &vINTDeviceSupportsSetSpeed)
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
		return (vINTDeviceSupportsSetSpeed == 0 ? false : true)
	}

	/**
	Writes a label to the device in the form of a string in the device flash memory. This label can then be used to identify the device, and will persist across power cycles.  
	  
	The label can be at most 10 UTF-16 code units. Most unicode characters take up a single code unit, but some, such as emoji, can take several.  
	  
	Some older devices can not have their labels set from Windows. For these devices the label should be set from Linux or macOS.  
	  
	Note: You should be careful when writing labels in your code, because the label is stored in flash which can only be re-written around 10,000 times before it will no longer write. If your program is complex, be sure to test it thoroughly before using WriteLabel to avoid accidentally burning out the flash.

	- throws:
	An error or type `PhidgetError`

	- parameters:
		- deviceLabel: The device label
	*/
	public func writeDeviceLabel(deviceLabel: String) throws {
		let result: PhidgetReturnCode
		result = Phidget_writeDeviceLabel(chandle, deviceLabel)
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
	}

	internal func initializeEvents() { initializeBaseEvents() }
	internal func initializeBaseEvents() {
		Phidget_setOnAttachHandler(chandle, nativeAttachHandler, UnsafeMutableRawPointer(selfCtx!.toOpaque()))
		Phidget_setOnDetachHandler(chandle, nativeDetachHandler, UnsafeMutableRawPointer(selfCtx!.toOpaque()))
		Phidget_setOnErrorHandler(chandle, nativeErrorHandler, UnsafeMutableRawPointer(selfCtx!.toOpaque()))
		Phidget_setOnPropertyChangeHandler(chandle, nativePropertyChangeHandler, UnsafeMutableRawPointer(selfCtx!.toOpaque()))
	}

	internal func uninitializeEvents() { uninitializeBaseEvents() }
	internal func uninitializeBaseEvents() {
		Phidget_setOnAttachHandler(chandle, nil, nil)
		Phidget_setOnDetachHandler(chandle, nil, nil)
		Phidget_setOnErrorHandler(chandle, nil, nil)
		Phidget_setOnPropertyChangeHandler(chandle, nil, nil)
	}

	/**
	Occurs when the channel is attached to a physical channel on a Phidget.  
	  
	`Attach` must be registered prior to calling `open()`, and will be called when the Phidget library matches the channel with a physical channel on a Phidget. `Attach` may be called more than once if the channel is detached during its lifetime.  
	  
	`Attach` is the recommended place to configuration properties of the channel such as the data interval or change trigger.
	*/
	public let attach = SimpleEvent<Phidget> ()
	let nativeAttachHandler : Phidget_OnAttachCallback = { ch, ctx in
		let me = Unmanaged<Phidget>.fromOpaque(ctx!).takeUnretainedValue()
		me.attach.raise(me);
	}

	/**
	Occurs when the channel is detached from a Phidget device channel.`Detach` typically occurs when the Phidget device is removed from the system.
	*/
	public let detach = SimpleEvent<Phidget> ()
	let nativeDetachHandler : Phidget_OnDetachCallback = { ch, ctx in
		let me = Unmanaged<Phidget>.fromOpaque(ctx!).takeUnretainedValue()
		me.detach.raise(me);
	}

	/**
	`Error` is called when an error condition has been detected.  
	  
	See the documentation for your specific channel class to see what error events it might throw.

	---
	## Parameters:
	*   `code`: The error code
	*   `description`: The error description
	*/
	public let error = Event<Phidget, (code: ErrorEventCode, description: String)> ()
	let nativeErrorHandler : Phidget_OnErrorCallback = { ch, ctx, code, description in
		let me = Unmanaged<Phidget>.fromOpaque(ctx!).takeUnretainedValue()
		me.error.raise(me, (ErrorEventCode(rawValue: code.rawValue)!, String(cString: description!)));
	}

	/**
	Occurs when a property is changed externally from the user channel, usually from a network client attached to the same channel.

	---
	## Parameters:
	*   `propertyName`: The name of the property that has changed
	*/
	public let propertyChange = Event<Phidget, String> ()
	let nativePropertyChangeHandler : Phidget_OnPropertyChangeCallback = { ch, ctx, propertyName in
		let me = Unmanaged<Phidget>.fromOpaque(ctx!).takeUnretainedValue()
		me.propertyChange.raise(me, String(cString: propertyName!));
	}

}
