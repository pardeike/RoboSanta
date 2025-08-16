import Foundation
//import Phidget22

/**
The Phidget Manager allows tracking of which Phidgets are available to be controlled from the current program. This is useful for listing all available Phidgets so you can select which ones to use at runtime.

You do not need to use a Phidget Manager if you know what Phidgets will be required for your application in advance.

Phidget channels that become available will each send an **Attach** event, and Phidgets that are removed from the system will send corresponding **Detach** events. If you are using a Phidget Manager, your program is responsible for keeping track of available Phidgets using these events.
*/
public class ManagerBase {

	var chandle: PhidgetManagerHandle?
	var selfCtx: Unmanaged<ManagerBase>?
	internal static func createRetainedTypedPhidget(_ handle: PhidgetHandle) -> Phidget {
		var cclass: Phidget_ChannelClass = PHIDCHCLASS_NOTHING
		var isChannel: Int32 = 0
		var phid: Phidget
		Phidget_getChannelClass(handle, &cclass)
		Phidget_getIsChannel(handle, &isChannel)
		switch (cclass) {
		case PHIDCHCLASS_ACCELEROMETER:
			phid = Accelerometer(handle)
		case PHIDCHCLASS_BLDCMOTOR:
			phid = BLDCMotor(handle)
		case PHIDCHCLASS_CAPACITIVETOUCH:
			phid = CapacitiveTouch(handle)
		case PHIDCHCLASS_CURRENTINPUT:
			phid = CurrentInput(handle)
		case PHIDCHCLASS_DCMOTOR:
			phid = DCMotor(handle)
		case PHIDCHCLASS_DICTIONARY:
			phid = Dictionary(handle)
		case PHIDCHCLASS_DIGITALINPUT:
			phid = DigitalInput(handle)
		case PHIDCHCLASS_DIGITALOUTPUT:
			phid = DigitalOutput(handle)
		case PHIDCHCLASS_DISTANCESENSOR:
			phid = DistanceSensor(handle)
		case PHIDCHCLASS_ENCODER:
			phid = Encoder(handle)
		case PHIDCHCLASS_FREQUENCYCOUNTER:
			phid = FrequencyCounter(handle)
		case PHIDCHCLASS_GPS:
			phid = GPS(handle)
		case PHIDCHCLASS_GYROSCOPE:
			phid = Gyroscope(handle)
		case PHIDCHCLASS_HUB:
			phid = Hub(handle)
		case PHIDCHCLASS_HUMIDITYSENSOR:
			phid = HumiditySensor(handle)
		case PHIDCHCLASS_IR:
			phid = IR(handle)
		case PHIDCHCLASS_LCD:
			phid = LCD(handle)
		case PHIDCHCLASS_LIGHTSENSOR:
			phid = LightSensor(handle)
		case PHIDCHCLASS_MAGNETOMETER:
			phid = Magnetometer(handle)
		case PHIDCHCLASS_MOTORPOSITIONCONTROLLER:
			phid = MotorPositionController(handle)
		case PHIDCHCLASS_MOTORVELOCITYCONTROLLER:
			phid = MotorVelocityController(handle)
		case PHIDCHCLASS_PHSENSOR:
			phid = PHSensor(handle)
		case PHIDCHCLASS_POWERGUARD:
			phid = PowerGuard(handle)
		case PHIDCHCLASS_PRESSURESENSOR:
			phid = PressureSensor(handle)
		case PHIDCHCLASS_RCSERVO:
			phid = RCServo(handle)
		case PHIDCHCLASS_RFID:
			phid = RFID(handle)
		case PHIDCHCLASS_RESISTANCEINPUT:
			phid = ResistanceInput(handle)
		case PHIDCHCLASS_SOUNDSENSOR:
			phid = SoundSensor(handle)
		case PHIDCHCLASS_SPATIAL:
			phid = Spatial(handle)
		case PHIDCHCLASS_STEPPER:
			phid = Stepper(handle)
		case PHIDCHCLASS_TEMPERATURESENSOR:
			phid = TemperatureSensor(handle)
		case PHIDCHCLASS_VOLTAGEINPUT:
			phid = VoltageInput(handle)
		case PHIDCHCLASS_VOLTAGEOUTPUT:
			phid = VoltageOutput(handle)
		case PHIDCHCLASS_VOLTAGERATIOINPUT:
			phid = VoltageRatioInput(handle)
		default:
			phid = Phidget(handle)
		}
		if isChannel == 1 {
			Phidget_retain(handle)
		}
		phid.retained = true
		return phid
	}

	public init() {
		var h: PhidgetHandle?
		PhidgetManager_create(&h)
		chandle = h
		selfCtx = Unmanaged.passUnretained(self)
		initializeEvents()
	}

	deinit {
		uninitializeEvents()
		PhidgetManager_delete(&chandle)
	}

	/**
	Closes a Phidget Manager that has been opened.

	- throws:
	An error or type `PhidgetError`
	*/
	public func close() throws {
		let result: PhidgetReturnCode
		result = PhidgetManager_close(chandle)
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
	}

	/**
	Opens the Phidget Manager.  
	  
	Be sure to register **Attach** and **Detach** event handlers for the Manager before opening it, to ensure you program doesn't miss the events reported for devices already connected to your system.

	- throws:
	An error or type `PhidgetError`
	*/
	public func open() throws {
		let result: PhidgetReturnCode
		result = PhidgetManager_open(chandle)
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
	}

	internal func initializeEvents() { initializeBaseEvents() }
	internal func initializeBaseEvents() {
		PhidgetManager_setOnAttachHandler(chandle, nativeAttachHandler, UnsafeMutableRawPointer(selfCtx!.toOpaque()))
		PhidgetManager_setOnDetachHandler(chandle, nativeDetachHandler, UnsafeMutableRawPointer(selfCtx!.toOpaque()))
	}

	internal func uninitializeEvents() { uninitializeBaseEvents() }
	internal func uninitializeBaseEvents() {
		PhidgetManager_setOnAttachHandler(chandle, nil, nil)
		PhidgetManager_setOnDetachHandler(chandle, nil, nil)
	}

	/**
	Occurs when a channel is attached.

	*   Phidget channels you get from the manager are informational only, you can read information about them such as serial number, class, name, etc. but they are not opened. In order to interact with one, you must `create` and `open` a Phidget object of the correct type.

	---
	## Parameters:
	*   `channel`: The Phidget channel that attached
	*/
	public let attach = Event<Manager, Phidget> ()
	let nativeAttachHandler : PhidgetManager_OnAttachCallback = { ch, ctx, channel in
		let me = Unmanaged<Manager>.fromOpaque(ctx!).takeUnretainedValue()
		me.attach.raise(me, Manager.createRetainedTypedPhidget(channel!));
	}

	/**
	Occurs when a channel is detached.

	*   Phidget channels you get from the manager are informational only, you can read information about them such as serial number, class, name, etc. but they are not opened. In order to interact with one, you must `create` and `open` a Phidget object of the correct type.

	---
	## Parameters:
	*   `channel`: The Phidget channel that detached
	*/
	public let detach = Event<Manager, Phidget> ()
	let nativeDetachHandler : PhidgetManager_OnDetachCallback = { ch, ctx, channel in
		let me = Unmanaged<Manager>.fromOpaque(ctx!).takeUnretainedValue()
		me.detach.raise(me, Manager.createRetainedTypedPhidget(channel!));
	}

}
