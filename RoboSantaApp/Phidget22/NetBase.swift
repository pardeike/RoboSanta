import Foundation
//import Phidget22

/**
The Phidget NET class controls all network functionality of a Phidget program, and allows for the use of remote Phidgets in your program. It can be used to enable automated Phidget server discovery over the local network, and to connect to or reject specific servers.

For basic use of the Net class, the only functions you need to worry about are **EnableServerDiscovery** and **AddServer**. In most cases, you can use **EnableServerDiscovery** with server type **DEVICEREMOTE** to automatically connect to Phidget servers on your local network. You can use **AddServer** to connect to servers that aren't discoverable on your local network.

To connect to a password-protected discoverable server on your local network, you can use **SetServerPassword** to specify the password to connect to that server.

If for some reason you need to prevent your program from discovering a non-password-protected server on your local network, you can call **DisableServer** directly after calling **EnableServerDiscovery**.

You must enable server discovery or add at least one server before setting other properties of this class, such as disabling servers, or setting server passwords. Similarly, server discovery must remain enabled, or at least one server must remain added, to maintain memory of those preferences.
*/
public class NetBase {

	/**
	PhidgetServer flag indicating that the server requires a password to authenticate
	*/
	public static let authRequired: Int = 1

	/**
	Registers a server that the client (your program) will try to connect to. The client will continually try to connect to the server, increasing the time between each attempt to a maximum interval of 16 seconds.  
	  
	This call is intended for use when server discovery is not enabled, or to connect to a server that is not discoverable.  
	  
	The server name used by this function does not have to match the name of the server running on the host machine. Only the address, port, and password need to match.  
	  
	This call will fail if a server with the same name has already been discovered.  
	  
	This call will fail if `setServerPassword()` has already been called with the same server name, as `setServerPassword()` registers the server entry anticipating the discovery of the server.  
	  
	See:

	*   `removeServer()`
	*   `enableServerDiscovery()`

	- throws:
	An error or type `PhidgetError`

	- parameters:
		- serverName: A unique name for the server (not the hostname)
		- address: The hostname or address of the server to connect to
		- port: The port number of the server to connect to
		- password: The password for the server to connect to (empty string if no password is required)
		- flags: connection flags: should be set to 0
	*/
	public static func addServer(serverName: String, address: String, port: Int, password: String = "", flags: Int = 0) throws {
		let result: PhidgetReturnCode
		result = PhidgetNet_addServer(serverName, address, Int32(port), password, Int32(flags))
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
	}

	/**
	Removes a registration for a server that the client (your program) is trying to connect to.If the client is currently connected to the server, the connection will be closed.  
	  
	If the server was discovered (not added by `addServer()`), the connection may be reestablished if and when the server is rediscovered. `disableServer()` should be used to prevent the reconnection of a discovered server  
	  
	See:

	*   `addServer()`
	*   `disableServer()`
	*   `disableServerDiscovery()`

	- throws:
	An error or type `PhidgetError`

	- parameters:
		- serverName: The name of the server to remove
	*/
	public static func removeServer(serverName: String) throws {
		let result: PhidgetReturnCode
		result = PhidgetNet_removeServer(serverName)
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
	}

	/**
	Enables attempts to connect to a discovered server, if attempts were previously disabled by `disableServer()`. All servers are enabled by default.  
	  
	This call will fail if the server was not previously added, disabled or discovered.  
	  
	See:

	*   `disableServer()`

	- throws:
	An error or type `PhidgetError`

	- parameters:
		- serverName: The name of the server to enable
	*/
	public static func enableServer(serverName: String) throws {
		let result: PhidgetReturnCode
		result = PhidgetNet_enableServer(serverName)
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
	}

	/**
	Prevents attempts to automatically connect to a server.

	By default the client (your program) will continually attempt to connect to added or discovered servers.This call will disable those attempts, but will not close an already established connection.  
	  
	See:

	*   `addServer()`
	*   `enableServer()`
	*   `enableServerDiscovery()`

	- throws:
	An error or type `PhidgetError`

	- parameters:
		- serverName: The name of the server to stop connections to
		- flags: Should be 0
	*/
	public static func disableServer(serverName: String, flags: Int = 0) throws {
		let result: PhidgetReturnCode
		result = PhidgetNet_disableServer(serverName, Int32(flags))
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
	}

	/**
	Enables the dynamic discovery of servers that publish their identity to the network. Currently Multicast DNS is used to discover and publish Phidget servers.

	To connect to remote Phidgets, call this function with server type `ServerType.deviceRemote`.

	`enableServerDiscovery()` must be called once for each server type your program requires. Multiple calls for the same server type are ignored

	This call will fail with the error code `ErrorCode.unsupported` if your computer does not have the required mDNS support. We recommend using Bonjour Print Services on Windows and Mac, or Avahi on Linux.

	  
	  
	See:

	*   `disableServerDiscovery()`
	*   `addServer()`

	- throws:
	An error or type `PhidgetError`

	- parameters:
		- serverType: The server type listen for
	*/
	public static func enableServerDiscovery(serverType: ServerType = .deviceRemote) throws {
		let result: PhidgetReturnCode
		result = PhidgetNet_enableServerDiscovery(PhidgetServerType(serverType.rawValue))
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
	}

	/**
	Disables the dynamic discovery of servers that publish their identity.

	`disableServerDiscovery()` does not disconnect already established connections.  
	  
	See:

	*   `enableServerDiscovery()`
	*   `disableServer()`
	*   `removeServer()`

	- throws:
	An error or type `PhidgetError`

	- parameters:
		- serverType: The server type to disable
	*/
	public static func disableServerDiscovery(serverType: ServerType = .deviceRemote) throws {
		let result: PhidgetReturnCode
		result = PhidgetNet_disableServerDiscovery(PhidgetServerType(serverType.rawValue))
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
	}

	/**
	Sets the password that will be used to attempt to connect to the server. If the server has not already been added or discovered, a placeholder server entry will be registered to use this password on the server once it is discovered.

	- throws:
	An error or type `PhidgetError`

	- parameters:
		- serverName: The name of the server
		- password: The password to use for the server (empty string if no password)
	*/
	public static func setServerPassword(serverName: String, password: String) throws {
		let result: PhidgetReturnCode
		result = PhidgetNet_setServerPassword(serverName, password)
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
	}

	/**
	Subscribe to this event if you would like to know when a server has been added.

	---
	## Parameters:
	*   `server`: The server that has been added.
	*   `kv`: Opaque structure containing keys related to the server
	public static let serverAdded = StaticEvent<(server: PhidgetServer, kv: UnsafeRawPointer)> ( cinit: { PhidgetNet_setOnServerAddedHandler(nativeServerAddedHandler, nil) } )
	static let nativeServerAddedHandler : PhidgetNet_OnServerAddedCallback = { ctx, server, kv in
		Net.serverAdded.raise((PhidgetServer(server!.pointee), UnsafeRawPointer(kv!)));
	}
    */

	/**
	Subscribe to this event if you would like to know when a server has been removed.

	---
	## Parameters:
	*   `server`: The server that has been removed.
	public static let serverRemoved = StaticEvent<PhidgetServer> ( cinit: { PhidgetNet_setOnServerRemovedHandler(nativeServerRemovedHandler, nil) } )
	static let nativeServerRemovedHandler : PhidgetNet_OnServerRemovedCallback = { ctx, server in
		Net.serverRemoved.raise(PhidgetServer(server!.pointee));
	}
    */  

}
