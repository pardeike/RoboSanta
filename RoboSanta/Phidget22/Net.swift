import Foundation
//import Phidget22

/**
The Phidget NET class controls all network functionality of a Phidget program, and allows for the use of remote Phidgets in your program. It can be used to enable automated Phidget server discovery over the local network, and to connect to or reject specific servers.

For basic use of the Net class, the only functions you need to worry about are **EnableServerDiscovery** and **AddServer**. In most cases, you can use **EnableServerDiscovery** with server type **DEVICEREMOTE** to automatically connect to Phidget servers on your local network. You can use **AddServer** to connect to servers that aren't discoverable on your local network.

To connect to a password-protected discoverable server on your local network, you can use **SetServerPassword** to specify the password to connect to that server.

If for some reason you need to prevent your program from discovering a non-password-protected server on your local network, you can call **DisableServer** directly after calling **EnableServerDiscovery**.

You must enable server discovery or add at least one server before setting other properties of this class, such as disabling servers, or setting server passwords. Similarly, server discovery must remain enabled, or at least one server must remain added, to maintain memory of those preferences.
*/
public class Net: NetBase {

}
