import Foundation
//import Phidget22

/**
The Phidget Manager allows tracking of which Phidgets are available to be controlled from the current program. This is useful for listing all available Phidgets so you can select which ones to use at runtime.

You do not need to use a Phidget Manager if you know what Phidgets will be required for your application in advance.

Phidget channels that become available will each send an **Attach** event, and Phidgets that are removed from the system will send corresponding **Detach** events. If you are using a Phidget Manager, your program is responsible for keeping track of available Phidgets using these events.
*/
public class Manager: ManagerBase {

}
