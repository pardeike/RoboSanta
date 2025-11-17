import Foundation
//import Phidget22

/**
Encoder interface mode
*/
public enum EncoderIOMode: UInt32 {
	/// No additional pull-up or pull-down resistors will be applied to the input lines.
	case pushPull = 1
	/// 2.2kΩ pull-down resistors will be applied to the input lines.
	case lineDriver_2K2 = 2
	/// 10kΩ pull-down resistors will be applied to the input lines.
	case lineDriver_10K = 3
	/// 2.2kΩ pull-up resistors will be applied to the input lines.
	case openCollector_2K2 = 4
	/// 10kΩ pull-up resistors will be applied to the input lines.
	case openCollector_10K = 5
}
/**
Error codes returned from all API calls via Exceptions.
*/
public enum ErrorCode: UInt32, Sendable {
	/// Call succeeded.
	case success = 0
	/// Not Permitted
	case notPermitted = 1
	/// The specified entity does not exist. This is usually a result of Net or Log API calls.
	case noSuchEntity = 2
	/// Call has timed out. This can happen for a number of common reasons: Check that the Phidget you are trying to open is plugged in, and that the addressing parameters have been specified correctly. Check that the Phidget is not already open in another program, such as the Phidget Control Panel, or another program you are developing. If your Phidget has a plug or terminal block for external power, ensure it is plugged in and powered. If you are using remote Phidgets, ensure that your computer can access the remote Phidgets using the Phidget Control Panel. If you are using remote Phidgets, ensure you have enabled Server Discovery or added the server corresponding to the Phidget you are trying to open. If you are using Network Server Discovery, try extending the timeout to allow more time for the server to be discovered.
	case timeout = 3
	/// Keep Alive Failure
	case keepAlive = 58
	/// The operation was interrupted; either from an error, or because the device was closed.
	case interrupted = 4
	/// IO Issue
	case IO = 5
	/// Memory Issue
	case noMemory = 6
	/// Access to the resource (file) is denied. This can happen when enabling logging.
	case access = 7
	/// Address Issue
	case fault = 8
	/// Specified resource is in use. This error code is not normally used.
	case busy = 9
	/// Object Exists
	case exists = 10
	/// Object is not a directory
	case isNotDirectory = 11
	/// Object is a directory
	case isDirectory = 12
	/// Invalid or malformed command. This can be caused by sending a command to a device which is not supported in it's current configuration.
	case invalid = 13
	/// Too many open files in system
	case tooManyFilesSystem = 14
	/// Too many open files
	case tooManyFiles = 15
	/// The provided buffer argument size is too small.
	case noSpace = 16
	/// File too Big
	case fileTooBig = 17
	/// Read Only Filesystem
	case readOnlyFilesystem = 18
	/// Read Only Object
	case readOnly = 19
	/// This API call is not supported. For Class APIs this means that this API is not supported by this device. This can also mean the API is not supported on this OS, or OS configuration.
	case unsupported = 20
	/// One or more of the parameters passed to the function is not accepted by the channel in its current configuration.
	case invalidArgument = 21
	/// Try again
	case tryAgain = 22
	/// Not Empty
	case notEmpty = 26
	/// Something unexpected has occured. Enable library logging and have a look at the log, or contact Phidgets support.
	case unexpected = 28
	/// Duplicated request. Can happen with some Net API calls, such as trying to add the same server twice.
	case duplicate = 27
	/// Bad Credential
	case badPassword = 37
	/// Network Unavailable
	case networkUnavailable = 45
	/// Connection Refused
	case connectionRefused = 35
	/// Connection Reset
	case connectionReset = 46
	/// No route to host
	case hostUnreachable = 48
	/// No Such Device
	case noSuchDevice = 40
	/// A Phidget channel object of the wrong channel class was passed into this API call.
	case wrongDevice = 50
	/// Broken Pipe
	case brokenPipe = 41
	/// Name Resolution Failure
	case nameResolutionFailure = 44
	/// The value is unknown. This can happen right after attach, when the value has not yet been received from the Phidget. This can also happen if a device has not yet been configured / enabled. Some properties can only be read back after being set.
	case unknownValue = 51
	/// This can happen for a number of common reasons. Be sure you are opening the channel before trying to use it. If you are opening the channel, the program may not be waiting for the channel to be attached. If possible use openWaitForAttachment. Otherwise, be sure to check the Attached property of the channel before trying to use it.
	case notAttached = 52
	/// Invalid or Unexpected Packet
	case invalidPacket = 53
	/// Argument List Too Long
	case tooBig = 54
	/// Bad Version
	case badVersion = 55
	/// Channel was closed. This can happen if a channel is closed while openWaitForAttachment is waiting.
	case closed = 56
	/// Device is not configured enough for this API call. Have a look at the must-set properties for this device and make sure to configure them first.
	case notConfigured = 57
	/// End of File
	case endOfFile = 31
	/// Failsafe Triggered on this channel. Close and Re-open the channel to resume operation.
	case failsafe = 59
	/// The value has been measured to be higher than the valid range of the sensor.
	case unknownValueHigh = 60
	/// The value has been measured to be lower than the valid range of the sensor.
	case unknownValueLow = 61
	/// The power supply of your device is outside the acceptable range to allow operation.
	case badPower = 62
	/// Something has caused your device to decide it needs to be powered off and on to resume operation.
	case powerCycle = 63
	/// The hall sensor on your Brushless DC Motor Controller is Improperly Connected
	case HALLSENSOR = 64
	/// Current sensor offset outside acceptable bounds. Move the sensor aways from magnetic fields and try again.
	case BADCURRENT = 65
	/// One or more required connections on the device has been deemed faulty. Check your connections and try again.
	case BADCONNECTION = 66
	/// An external device has responded with a NACK response. Evaluate whether this is expected and try again.
	case NACK = 67
}
/**
The error code from an Error event
*/
public enum ErrorEventCode: UInt32 {
	/// Client and Server protocol versions don't match. Ensure that both sides are using the same release of phidget22.
	case badVersion = 1
	/// Check that the Phidget is not already open in another program, such as the Phidget Control Panel, or another program you are developing.
	case busy = 2
	/// This could be a network communication issue, an authentication issue (if server password is enabled), or a Device access / hardware issue.
	case network = 3
	/// An error occured dispatching a command or event.
	case dispatch = 4
	/// A general failure occured - see description for details.
	case failure = 5
	/// An error state has cleared.
	case success = 4096
	/// A sampling overrun happened in firmware.
	case overrun = 4098
	/// One or more packets were lost.
	case packetLost = 4099
	/// Variable has wrapped around.
	case wrapAround = 4100
	/// Over-temperature condition detected.
	case overTemperature = 4101
	/// Over-current condition detected.
	case overCurrent = 4102
	/// Out of range condition detected.
	case outOfRange = 4103
	/// Power supply problem detected.
	case badPower = 4104
	/// Saturation condition detected.
	case saturation = 4105
	/// Over-voltage condition detected.
	case overVoltage = 4107
	/// Failsafe condition detected.
	case failsafeCondition = 4108
	/// Voltage error detected.
	case voltageError = 4109
	/// Energy dump condition detected.
	case energyDumpCondition = 4110
	/// Motor stall detected.
	case motorStallCondition = 4111
	/// Invalid state detected.
	case invalidStateCondition = 4112
	/// Bad connection detected.
	case badConnectionCondition = 4113
	/// Measurement is above the valid range.
	case outOfRangeHighCondition = 4114
	/// Measurement is below the valid range.
	case outOfRangeLowCondition = 4115
	/// Fault condition detected.
	case fault = 4116
	/// External stop condition detected.
	case EStop = 4117
	/// Current sensor problem detected.
	case badCurrent = 4118
}
/**
Phidget device ID
*/
public enum DeviceID: UInt32 {
	/// Unknown Device
	case unknown = 125
	/// Hub Port - Digital Input mode
	case digitalInputPort = 95
	/// Hub Port - Digital Output mode
	case digitalOutputPort = 96
	/// Hub Port - Voltage Input mode
	case voltageInputPort = 97
	/// Hub Port - Voltage Ratio Input mode
	case voltageRatioInputPort = 98
	/// Dictionary
	case PN_DICTIONARY = 111
	/// PhidgetServo 1-Motor (1000)
	case PN_1000 = 2
	/// PhidgetServo 4-Motor (1001)
	case PN_1001 = 3
	/// PhidgetAnalog 4-Output (1002)
	case PN_1002 = 4
	/// PhidgetAccelerometer 2-Axis (1008)
	case PN_1008 = 5
	/// PhidgetInterfaceKit 8/8/8 (1010, 1013, 1018, 1019)
	case PN_1010_1013_1018_1019 = 6
	/// PhidgetInterfaceKit 2/2/2 (1011)
	case PN_1011 = 7
	/// PhidgetInterfaceKit 0/16/16 (1012)
	case PN_1012 = 8
	/// PhidgetInterfaceKit 0/0/4 (1014)
	case PN_1014 = 9
	/// PhidgetLinearTouch (1015)
	case PN_1015 = 10
	/// PhidgetCircularTouch (1016)
	case PN_1016 = 11
	/// PhidgetInterfaceKit 0/0/8 (1017)
	case PN_1017 = 12
	/// PhidgetRFID (1023)
	case PN_1023 = 13
	/// PhidgetRFID Read-Write (1024)
	case PN_1024 = 14
	/// PhidgetLED-64 (1030)
	case PN_1030 = 15
	/// PhidgetLED-64 Advanced (1031)
	case PN_1031 = 16
	/// PhidgetLED-64 Advanced (1032)
	case PN_1032 = 17
	/// PhidgetGPS (1040)
	case PN_1040 = 18
	/// PhidgetSpatial 0/0/3 Basic (1041)
	case PN_1041 = 19
	/// PhidgetSpatial 3/3/3 Basic (1042)
	case PN_1042 = 20
	/// PhidgetSpatial Precision 0/0/3 High Resolution (1043)
	case PN_1043 = 21
	/// PhidgetSpatial Precision 3/3/3 High Resolution (1044)
	case PN_1044 = 22
	/// PhidgetTemperatureSensor IR (1045)
	case PN_1045 = 23
	/// PhidgetBridge 4-Input (1046)
	case PN_1046 = 24
	/// PhidgetEncoder HighSpeed 4-Input (1047)
	case PN_1047 = 25
	/// PhidgetTemperatureSensor 4-Input (1048)
	case PN_1048 = 26
	/// PhidgetSpatial 0/0/3 (1049)
	case PN_1049 = 27
	/// PhidgetTemperatureSensor 1-Input (1051)
	case PN_1051 = 28
	/// PhidgetEncoder (1052)
	case PN_1052 = 29
	/// PhidgetAccelerometer 2-Axis (1053)
	case PN_1053 = 30
	/// PhidgetFrequencyCounter (1054)
	case PN_1054 = 31
	/// PhidgetIR (1055)
	case PN_1055 = 32
	/// PhidgetSpatial 3/3/3 (1056)
	case PN_1056 = 33
	/// PhidgetEncoder HighSpeed (1057)
	case PN_1057 = 34
	/// PhidgetPHSensor (1058)
	case PN_1058 = 35
	/// PhidgetAccelerometer 3-Axis (1059)
	case PN_1059 = 36
	/// PhidgetMotorControl LV (1060)
	case PN_1060 = 37
	/// PhidgetAdvancedServo 8-Motor (1061)
	case PN_1061 = 38
	/// PhidgetStepper Unipolar 4-Motor (1062)
	case PN_1062 = 39
	/// PhidgetStepper Bipolar 1-Motor (1063)
	case PN_1063 = 40
	/// PhidgetMotorControl HC (1064)
	case PN_1064 = 41
	/// PhidgetMotorControl 1-Motor (1065)
	case PN_1065 = 42
	/// PhidgetAdvancedServo 1-Motor (1066)
	case PN_1066 = 43
	/// PhidgetStepper Bipolar HC (1067)
	case PN_1067 = 44
	/// PhidgetTextLCD 20x2 with PhidgetInterfaceKit 8/8/8 (1202, 1203)
	case PN_1202_1203 = 45
	/// PhidgetTextLCD Adapter (1204)
	case PN_1204 = 46
	/// PhidgetTextLCD 20x2 (1215, 1216, 1217, 1218)
	case PN_1215__1218 = 47
	/// PhidgetTextLCD 20x2 with PhidgetInterfaceKit 0/8/8 (1219, 1220, 1221, 1222)
	case PN_1219__1222 = 48
	/// pH Adapter Phidget (ADP1000)
	case PN_ADP1000 = 49
	/// 8x Voltage Input Phidget (DAQ1000)
	case PN_DAQ1000 = 51
	/// 4x Digital Input Phidget (DAQ1200)
	case PN_DAQ1200 = 52
	/// 4x Isolated Digital Input Phidget (DAQ1300)
	case PN_DAQ1300 = 53
	/// 16x Isolated Digital Input Phidget (DAQ1301)
	case PN_DAQ1301 = 54
	/// Versatile Input Phidget (DAQ1400)
	case PN_DAQ1400 = 55
	/// Wheatstone Bridge Phidget (DAQ1500)
	case PN_DAQ1500 = 56
	/// DC Motor Phidget (DCC1000)
	case PN_DCC1000 = 57
	/// 2A DC Motor Phidget (DCC1001)
	case PN_DCC1001 = 110
	/// 4A DC Motor Phidget (DCC1002)
	case PN_DCC1002 = 117
	/// 2x DC Motor Phidget (DCC1003)
	case PN_DCC1003 = 120
	/// 30V 50A DC Motor Phidget (DCC1020)
	case PN_DCC1020 = 128
	/// Brushless DC Motor Phidget (DCC1100)
	case PN_DCC1100 = 108
	/// 30V 50A Brushless DC Motor Phidget (DCC1120)
	case PN_DCC1120 = 150
	/// Distance Phidget (DST1000)
	case PN_DST1000 = 58
	/// Distance Phidget 650mm (DST1001)
	case PN_DST1001 = 121
	/// Distance Phidget 1300mm (DST1002)
	case PN_DST1002 = 126
	/// Sonar Phidget (DST1200)
	case PN_DST1200 = 59
	/// Quadrature Encoder Phidget (ENC1000)
	case PN_ENC1000 = 60
	/// Quadrature Encoder Phidget (ENC1001)
	case PN_ENC1001 = 155
	/// Touch Keypad Phidget (HIN1000)
	case PN_HIN1000 = 61
	/// Touch Wheel Phidget (HIN1001)
	case PN_HIN1001 = 62
	/// Thumbstick Phidget (HIN1100)
	case PN_HIN1100 = 63
	/// Phidget Dial (HIN1101)
	case PN_HIN1101 = 109
	/// 6-Port USB VINT Hub Phidget (HUB0000)
	case PN_HUB0000 = 64
	/// 6-Port USB VINT Hub Phidget (HUB0001)
	case PN_HUB0001 = 142
	/// 6-Port USB VINT Hub Phidget (HUB0002)
	case PN_HUB0002 = 147
	/// 6-Port PhidgetSBC VINT Hub Phidget (HUB0004)
	case PN_HUB0004 = 67
	/// 1-Port USB VINT Hub Phidget (HUB0007)
	case PN_HUB0007 = 148
	/// 6-Port Network VINT Hub Phidget (HUB5000)
	case PN_HUB5000 = 123
	/// Humidity Phidget (HUM1000)
	case PN_HUM1000 = 69
	/// Humidity Phidget (HUM1001)
	case PN_HUM1001 = 127
	/// Soil Moisture Phidget (HUM1100)
	case PN_HUM1100 = 136
	/// Graphic LCD Phidget (LCD1100)
	case PN_LCD1100 = 70
	/// 32x Isolated LED Phidget (LED1000)
	case PN_LED1000 = 71
	/// Light Phidget (LUX1000)
	case PN_LUX1000 = 72
	/// PhidgetAccelerometer (MOT0100)
	case PN_MOT0100 = 146
	/// PhidgetSpatial Precision 3/3/3 (MOT0109)
	case PN_MOT0109 = 140
	/// PhidgetSpatial Precision 3/3/3 (MOT0110)
	case PN_MOT0110 = 141
	/// Accelerometer Phidget (MOT1100)
	case PN_MOT1100 = 73
	/// Spatial Phidget (MOT1101)
	case PN_MOT1101 = 74
	/// Spatial Phidget (MOT1102)
	case PN_MOT1102 = 137
	/// 12-bit Voltage Output Phidget (OUT1000)
	case PN_OUT1000 = 75
	/// Isolated 12-bit Voltage Output Phidget (OUT1001)
	case PN_OUT1001 = 76
	/// Isolated 16-bit Voltage Output Phidget (OUT1002)
	case PN_OUT1002 = 77
	/// 4x Digital Output Phidget (OUT1100)
	case PN_OUT1100 = 78
	/// Barometer Phidget (PRE1000)
	case PN_PRE1000 = 79
	/// PhidgetAdvancedServo 8-Motor (RCC0004)
	case PN_RCC0004 = 124
	/// 16x RC Servo Phidget (RCC1000)
	case PN_RCC1000 = 80
	/// 4x Relay Phidget (REL1000)
	case PN_REL1000 = 81
	/// 4x Isolated Solid State Relay Phidget (REL1100)
	case PN_REL1100 = 82
	/// 16x Isolated Solid State Relay Phidget (REL1101)
	case PN_REL1101 = 83
	/// Programmable Power Guard Phidget (SAF1000)
	case PN_SAF1000 = 84
	/// Sound Phidget (SND1000)
	case PN_SND1000 = 85
	/// Stepper Phidget (STC1000)
	case PN_STC1000 = 86
	/// 2.5A Stepper Phidget (STC1001)
	case PN_STC1001 = 115
	/// 8A Stepper Phidget (STC1002)
	case PN_STC1002 = 118
	/// 4A Stepper Phidget (STC1003)
	case PN_STC1003 = 119
	/// 4A Stepper Phidget (STC1005)
	case PN_STC1005 = 149
	/// Temperature Phidget (TMP1000)
	case PN_TMP1000 = 87
	/// Isolated Thermocouple Phidget (TMP1100)
	case PN_TMP1100 = 88
	/// 4x Thermocouple Phidget (TMP1101)
	case PN_TMP1101 = 89
	/// RTD Phidget (TMP1200)
	case PN_TMP1200 = 90
	/// 20-bit (+-40V) Voltage Input Phidget (VCP1000)
	case PN_VCP1000 = 92
	/// 10-bit (+-40V) Voltage Input Phidget (VCP1001)
	case PN_VCP1001 = 93
	/// 10-bit (+-1V) Voltage Input Phidget (VCP1002)
	case PN_VCP1002 = 94
	/// 30A Current Sensor Phidget (VCP1100)
	case PN_VCP1100 = 105
}
/**
Phidget logging level
*/
public enum LogLevel: UInt32 {
	/// Critical
	case critical = 1
	/// Error
	case error = 2
	/// Warning
	case warning = 3
	/// Info
	case info = 4
	/// Debug
	case debug = 5
	/// Verbose
	case verbose = 6
}
/**
Phidget device class
*/
public enum DeviceClass: UInt32 {
	/// PhidgetAccelerometer device
	case accelerometer = 1
	/// PhidgetAdvancedServo device
	case advancedServo = 2
	/// PhidgetAnalog device
	case analog = 3
	/// PhidgetBridge device
	case bridge = 4
	/// Dictionary device
	case dictionary = 24
	/// PhidgetEncoder device
	case encoder = 5
	/// PhidgetFrequencyCounter device
	case frequencyCounter = 6
	/// PhidgetGPS device
	case GPS = 7
	/// Phidget VINT Hub device
	case hub = 8
	/// PhidgetInterfaceKit device
	case interfaceKit = 9
	/// PhidgetIR device
	case IR = 10
	/// PhidgetLED device
	case LED = 11
	/// PhidgetMotorControl device
	case motorControl = 13
	/// PhidgetPHSensor device
	case PHSensor = 14
	/// PhidgetRFID device
	case RFID = 15
	/// PhidgetServo device
	case servo = 16
	/// PhidgetSpatial device
	case spatial = 17
	/// PhidgetStepper device
	case stepper = 18
	/// PhidgetTemperatureSensor device
	case temperatureSensor = 19
	/// PhidgetTextLCD device
	case textLCD = 20
	/// Phidget VINT device
	case VINT = 21
}
/**
Phidget channel class
*/
public enum ChannelClass: UInt32 {
	/// Accelerometer channel
	case accelerometer = 1
	/// Brushless DC motor channel
	case BLDCMotor = 35
	/// Capacitive Touch channel
	case capacitiveTouch = 14
	/// Current input channel
	case currentInput = 2
	/// DC motor channel
	case DCMotor = 4
	/// Dictionary
	case dictionary = 36
	/// Digital input channel
	case digitalInput = 5
	/// Digital output channel
	case digitalOutput = 6
	/// Distance sensor channel
	case distanceSensor = 7
	/// Encoder channel
	case encoder = 8
	/// Frequency counter channel
	case frequencyCounter = 9
	/// GPS channel
	case GPS = 10
	/// Gyroscope channel
	case gyroscope = 12
	/// VINT Hub channel
	case hub = 13
	/// Humidity sensor channel
	case humiditySensor = 15
	/// IR channel
	case IR = 16
	/// LCD channel
	case LCD = 11
	/// Light sensor channel
	case lightSensor = 17
	/// Magnetometer channel
	case magnetometer = 18
	/// Motor position control channel.
	case motorPositionController = 34
	/// Motor velocity control channel.
	case motorVelocityController = 39
	/// pH sensor channel
	case PHSensor = 37
	/// Power guard channel
	case powerGuard = 20
	/// Pressure sensor channel
	case pressureSensor = 21
	/// RC Servo channel
	case RCServo = 22
	/// Resistance input channel
	case resistanceInput = 23
	/// RFID channel
	case RFID = 24
	/// Sound sensor channel
	case soundSensor = 25
	/// Spatial channel
	case spatial = 26
	/// Stepper channel
	case stepper = 27
	/// Temperature sensor channel
	case temperatureSensor = 28
	/// Voltage input channel
	case voltageInput = 29
	/// Voltage output channel
	case voltageOutput = 30
	/// Voltage ratio input channel
	case voltageRatioInput = 31
}
/**
Phidget channel sub class
*/
public enum ChannelSubclass: UInt32 {
	/// No subclass
	case none = 1
	/// Digital output duty cycle
	case digitalOutputDutyCycle = 16
	/// Digital output frequency
	case digitalOutputFrequency = 18
	/// Digital output LED driver
	case digitalOutputLEDDriver = 17
	/// Encoder IO mode settable
	case encoderModeSettable = 96
	/// Graphic LCD
	case LCDGraphic = 80
	/// Text LCD
	case LCDText = 81
	/// Spatial AHRS/IMU
	case spatialAHRS = 112
	/// Temperature sensor RTD
	case temperatureSensorRTD = 32
	/// Temperature sensor thermocouple
	case temperatureSensorThermocouple = 33
	/// Voltage sensor port
	case voltageInputSensorPort = 48
	/// Voltage ratio bridge input
	case voltageRatioInputBridge = 65
	/// Voltage ratio sensor port
	case voltageRatioInputSensorPort = 64
}
/**
Phidget mesh mode
*/
public enum MeshMode: UInt32 {
	/// Router mode
	case router = 1
	/// Sleepy end device mode
	case sleepyEndDevice = 2
}
/**
The voltage level being provided to the sensor
*/
public enum PowerSupply: UInt32 {
	/// Switch the sensor power supply off
	case off = 1
	/// The sensor is provided with 12 volts
	case volts_12 = 2
	/// The sensor is provided with 24 volts
	case volts_24 = 3
}
/**
The DataAdapter Voltage
*/
public enum DataAdapterVoltage: UInt32 {
	/// Voltage supplied by external device
	case external = 1
	/// 2.5V
	case volts_2_5 = 3
	/// 3.3V
	case volts_3_3 = 4
	/// 5.0V
	case volts_5 = 5
}
/**
RTD wiring configuration
*/
public enum RTDWireSetup: UInt32 {
	/// Configures the device to make resistance calculations based on a 2-wire RTD setup.
	case wires_2 = 1
	/// Configures the device to make resistance calculations based on a 3-wire RTD setup.
	case wires_3 = 2
	/// Configures the device to make resistance calculations based on a 4-wire RTD setup.
	case wires_4 = 3
}
/**
The selected polarity mode for the digital input
*/
public enum InputMode: UInt32 {
	/// For interfacing NPN digital sensors
	case NPN = 1
	/// For interfacing PNP digital sensors
	case PNP = 2
	/// Floating input
	case floating = 3
	/// Enables a pullup for interfaces that only pull low
	case pullup = 4
}
/**
The operating condition of the fan. Choose between on, off, or automatic (based on temperature).
*/
public enum FanMode: UInt32 {
	/// Turns the fan off.
	case off = 1
	/// Turns the fan on.
	case on = 2
	/// The fan will be automatically controlled based on temperature.
	case auto = 3
}
/**
The drive type selection for the motor
*/
public enum DriveMode: UInt32 {
	/// Configures the motor for coasting deceleration
	case coast = 1
	/// Configures the motor for forced deceleration
	case forced = 2
}
/**
The position type selection
*/
public enum PositionType: UInt32 {
	/// Configures the controller to use the encoder as a position source
	case encoder = 1
	/// Configures the controller to use the hall-effect sensor as a position source
	case hallSensor = 2
}
/**
Controls how data from primary and backup spatial sensing chips are used.
*/
public enum SpatialPrecision: UInt32 {
	/// High precision sensor is used when possible, fallback to low precision sensor.
	case hybrid = 0
	/// High precision sensor is always used.
	case high = 1
	/// Low precision sensor is always used.
	case low = 2
}
/**
Analog sensor units. These correspond to the types of quantities that can be measured by Phidget analog sensors.
*/
public enum Unit: UInt32 {
	/// Unitless
	case none = 0
	/// Boolean
	case boolean = 1
	/// Percent
	case percent = 2
	/// Decibel
	case decibel = 3
	/// Millimeter
	case millimeter = 4
	/// Centimeter
	case centimeter = 5
	/// Meter
	case meter = 6
	/// Gram
	case gram = 7
	/// Kilogram
	case kilogram = 8
	/// Milliampere
	case milliampere = 9
	/// Ampere
	case ampere = 10
	/// Kilopascal
	case kilopascal = 11
	/// Volt
	case volt = 12
	/// Degree Celcius
	case degreeCelcius = 13
	/// Lux
	case lux = 14
	/// Gauss
	case gauss = 15
	/// pH
	case pH = 16
	/// Watt
	case watt = 17
}
/**
The name, symbol, and Phidgets enumeration of the units of the sensor value calculated from the analog sensor's measurements.
*/
public struct UnitInfo {
	/// Unit
	public var unit: Unit
	/// Name
	public var name: String
	/// Symbol
	public var symbol: String

	public init(
		unit: Unit,
		name: String,
		symbol: String
	) {
		self.unit = unit
		self.name = name
		self.symbol = symbol
	}

	internal init(_ cstruct: Phidget_UnitInfo) {
		unit = Unit(rawValue: cstruct.unit.rawValue)!
		name = String(cString: cstruct.name!)
		symbol = String(cString: cstruct.symbol!)
	}
	internal var cstruct: Phidget_UnitInfo {
		get {
			var cstruct: Phidget_UnitInfo = Phidget_UnitInfo()
			cstruct.unit = Phidget_Unit(unit.rawValue)
			cstruct.name = nil // NOTE: Not Supported
			cstruct.symbol = nil // NOTE: Not Supported
			return cstruct
		}
	}
}
/**
Phidget Server Types
*/
public enum ServerType: UInt32 {
	/// Phidget22 Server<br/>Server discovery with this server type allows discovery of servers hosting Phidget devices. Enabling server discovery with this server type allows automated connection to these servers, and the Phidgets connected to them. Enabling server discovery with this server type will also enable ServerAdded and ServerRemoved events for this server type.
	case deviceRemote = 3
	/// Phidget22 Web server<br/>Server discovery with this server type detects the presence of Phidget web servers used to communicate with in-browser JavaScript. Enabling server discovery with this server type will enable ServerAdded and ServerRemoved events for this server type.
	case WWWRemote = 6
	/// Phidget SBC<br/>Server discovery with this server type detects the presence of Network Phidgets (SBC3003, HUB5000, etc.). Enabling server discovery with this server type will enable ServerAdded and ServerRemoved events for this server type.
	case SBC = 7
}
/**
Describes a known server. See Constants for supported flags.
*/
public struct PhidgetServer {
	/// The name of the server
	public var name: String
	/// Name of the server type
	public var typeName: String
	/// The server type
	public var type: ServerType
	/// Flags describing the server state
	public var flags: Int
	/// The address of the server
	public var address: String
	/// The hostname of the server
	public var hostname: String
	/// The port number of the server
	public var port: Int

	public init(
		name: String,
		typeName: String,
		type: ServerType,
		flags: Int,
		address: String,
		hostname: String,
		port: Int
	) {
		self.name = name
		self.typeName = typeName
		self.type = type
		self.flags = flags
		self.address = address
		self.hostname = hostname
		self.port = port
	}

    /*
	internal init(_ cstruct: PhidgetServer) {
		name = String(cString: cstruct.name)
		typeName = String(cString: cstruct.typeName)
		type = ServerType(rawValue: cstruct.type.rawValue)!
		flags = Int(cstruct.flags)
		address = String(cString: cstruct.address)
		hostname = String(cString: cstruct.hostname)
		port = Int(cstruct.port)
	}
	internal var cstruct: PhidgetServer {
		get {
			var cstruct: PhidgetServer = PhidgetServer()
			cstruct.name = nil // NOTE: Not Supported
			cstruct.stype = nil // NOTE: Not Supported
			cstruct.type = PhidgetServerType(type.rawValue)
			cstruct.flags = Int32(flags)
			cstruct.addr = nil // NOTE: Not Supported
			cstruct.host = nil // NOTE: Not Supported
			cstruct.port = Int32(port)
			return cstruct
		}
	}
    */
}
/**
Bridge gain amplification setting. Higher gain results in better resolution, but narrower voltage range.
*/
public enum BridgeGain: UInt32 {
	/// 1x Amplificaion
	case gain_1x = 1
	/// 2x Amplification
	case gain_2x = 2
	/// 4x Amplification
	case gain_4x = 3
	/// 8x Amplification
	case gain_8x = 4
	/// 16x Amplification
	case gain_16x = 5
	/// 32x Amplification
	case gain_32x = 6
	/// 64x Amplification
	case gain_64x = 7
	/// 128x Amplification
	case gain_128x = 8
}
/**
The type of sensor attached to the voltage ratio input
*/
public enum VoltageRatioSensorType: UInt32 {
	/// Default. Configures the channel to be a generic ratiometric sensor. Unit is volts/volt.
	case voltageRatio = 0
	/// 1101 - IR Distance Adapter, with Sharp Distance Sensor 2D120X (4-30cm)
	case PN_1101_Sharp2D120X = 11011
	/// 1101 - IR Distance Adapter, with Sharp Distance Sensor 2Y0A21 (10-80cm)
	case PN_1101_Sharp2Y0A21 = 11012
	/// 1101 - IR Distance Adapter, with Sharp Distance Sensor 2Y0A02 (20-150cm)
	case PN_1101_Sharp2Y0A02 = 11013
	/// 1102 - IR Reflective Sensor 5mm
	case PN_1102 = 11020
	/// 1103 - IR Reflective Sensor 10cm
	case PN_1103 = 11030
	/// 1104 - Vibration Sensor
	case PN_1104 = 11040
	/// 1105 - Light Sensor
	case PN_1105 = 11050
	/// 1106 - Force Sensor
	case PN_1106 = 11060
	/// 1107 - Humidity Sensor
	case PN_1107 = 11070
	/// 1108 - Magnetic Sensor
	case PN_1108 = 11080
	/// 1109 - Rotation Sensor
	case PN_1109 = 11090
	/// 1110 - Touch Sensor
	case PN_1110 = 11100
	/// 1111 - Motion Sensor
	case PN_1111 = 11110
	/// 1112 - Slider 60
	case PN_1112 = 11120
	/// 1113 - Mini Joy Stick Sensor
	case PN_1113 = 11130
	/// 1115 - Pressure Sensor
	case PN_1115 = 11150
	/// 1116 - Multi-turn Rotation Sensor
	case PN_1116 = 11160
	/// 1118 - 50Amp Current Sensor AC
	case PN_1118_AC = 11181
	/// 1118 - 50Amp Current Sensor DC
	case PN_1118_DC = 11182
	/// 1119 - 20Amp Current Sensor AC
	case PN_1119_AC = 11191
	/// 1119 - 20Amp Current Sensor DC
	case PN_1119_DC = 11192
	/// 1120 - FlexiForce Adapter
	case PN_1120 = 11200
	/// 1121 - Voltage Divider
	case PN_1121 = 11210
	/// 1122 - 30 Amp Current Sensor AC
	case PN_1122_AC = 11221
	/// 1122 - 30 Amp Current Sensor DC
	case PN_1122_DC = 11222
	/// 1124 - Precision Temperature Sensor
	case PN_1124 = 11240
	/// 1125 - Humidity Sensor
	case PN_1125_Humidity = 11251
	/// 1125 - Temperature Sensor
	case PN_1125_Temperature = 11252
	/// 1126 - Differential Air Pressure Sensor +- 25kPa
	case PN_1126 = 11260
	/// 1128 - MaxBotix EZ-1 Sonar Sensor
	case PN_1128 = 11280
	/// 1129 - Touch Sensor
	case PN_1129 = 11290
	/// 1131 - Thin Force Sensor
	case PN_1131 = 11310
	/// 1134 - Switchable Voltage Divider
	case PN_1134 = 11340
	/// 1136 - Differential Air Pressure Sensor +-2 kPa
	case PN_1136 = 11360
	/// 1137 - Differential Air Pressure Sensor +-7 kPa
	case PN_1137 = 11370
	/// 1138 - Differential Air Pressure Sensor 50 kPa
	case PN_1138 = 11380
	/// 1139 - Differential Air Pressure Sensor 100 kPa
	case PN_1139 = 11390
	/// 1140 - Absolute Air Pressure Sensor 20-400 kPa
	case PN_1140 = 11400
	/// 1141 - Absolute Air Pressure Sensor 15-115 kPa
	case PN_1141 = 11410
	/// 1146 - IR Reflective Sensor 1-4mm
	case PN_1146 = 11460
	/// 3120 - Compression Load Cell (0-4.5 kg)
	case PN_3120 = 31200
	/// 3121 - Compression Load Cell (0-11.3 kg)
	case PN_3121 = 31210
	/// 3122 - Compression Load Cell (0-22.7 kg)
	case PN_3122 = 31220
	/// 3123 - Compression Load Cell (0-45.3 kg)
	case PN_3123 = 31230
	/// 3130 - Relative Humidity Sensor
	case PN_3130 = 31300
	/// 3520 - Sharp Distance Sensor (4-30cm)
	case PN_3520 = 35200
	/// 3521 - Sharp Distance Sensor (10-80cm)
	case PN_3521 = 35210
	/// 3522 - Sharp Distance Sensor (20-150cm)
	case PN_3522 = 35220
}
/**
The forward voltage setting of the LED
*/
public enum LEDForwardVoltage: UInt32 {
	/// 1.7 V
	case volts_1_7 = 1
	/// 2.75 V
	case volts_2_75 = 2
	/// 3.2 V
	case volts_3_2 = 3
	/// 3.9 V
	case volts_3_9 = 4
	/// 4.0 V
	case volts_4_0 = 5
	/// 4.8 V
	case volts_4_8 = 6
	/// 5.0 V
	case volts_5_0 = 7
	/// 5.6 V
	case volts_5_6 = 8
}
/**
Voltage supplied to all attached servos
*/
public enum RCServoVoltage: UInt32 {
	/// Run all servos on 5V DC
	case volts_5_0 = 1
	/// Run all servos on 6V DC
	case volts_6_0 = 2
	/// Run all servos on 7.4V DC
	case volts_7_4 = 3
}
/**
The selected output voltage range
*/
public enum VoltageOutputRange: UInt32 {
	/// ±10V DC
	case volts_10 = 1
	/// 0-5V DC
	case volts_5 = 2
}
/**
Measurement range of the voltage input. Larger ranges have less resolution.
*/
public enum VoltageRange: UInt32 {
	/// Range ±10mV DC
	case milliVolts_10 = 1
	/// Range ±40mV DC
	case milliVolts_40 = 2
	/// Range ±200mV DC
	case milliVolts_200 = 3
	/// Range ±312.5mV DC
	case milliVolts_312_5 = 4
	/// Range ±400mV DC
	case milliVolts_400 = 5
	/// Range ±1000mV DC
	case milliVolts_1000 = 6
	/// Range ±2V DC
	case volts_2 = 7
	/// Range ±5V DC
	case volts_5 = 8
	/// Range ±15V DC
	case volts_15 = 9
	/// Range ±40V DC
	case volts_40 = 10
	/// Auto-range mode changes based on the present voltage measurements.
	case auto = 11
}
/**
Type of sensor attached to the voltage input
*/
public enum VoltageSensorType: UInt32 {
	/// Default. Configures the channel to be a generic voltage sensor. Unit is volts.
	case voltage = 0
	/// 1114 - Temperature Sensor
	case PN_1114 = 11140
	/// 1117 - Voltage Sensor
	case PN_1117 = 11170
	/// 1123 - Precision Voltage Sensor
	case PN_1123 = 11230
	/// 1127 - Precision Light Sensor
	case PN_1127 = 11270
	/// 1130 - pH Adapter
	case PN_1130_pH = 11301
	/// 1130 - ORP Adapter
	case PN_1130_ORP = 11302
	/// 1132 - 4-20mA Adapter
	case PN_1132 = 11320
	/// 1133 - Sound Sensor
	case PN_1133 = 11330
	/// 1135 - Precision Voltage Sensor
	case PN_1135 = 11350
	/// 1142 - Light Sensor 1000 lux
	case PN_1142 = 11420
	/// 1143 - Light Sensor 70000 lux
	case PN_1143 = 11430
	/// 3500 - AC Current Sensor 10Amp
	case PN_3500 = 35000
	/// 3501 - AC Current Sensor 25Amp
	case PN_3501 = 35010
	/// 3502 - AC Current Sensor 50Amp
	case PN_3502 = 35020
	/// 3503 - AC Current Sensor 100Amp
	case PN_3503 = 35030
	/// 3507 - AC Voltage Sensor 0-250V (50Hz)
	case PN_3507 = 35070
	/// 3508 - AC Voltage Sensor 0-250V (60Hz)
	case PN_3508 = 35080
	/// 3509 - DC Voltage Sensor 0-200V
	case PN_3509 = 35090
	/// 3510 - DC Voltage Sensor 0-75V
	case PN_3510 = 35100
	/// 3511 - DC Current Sensor 0-10mA
	case PN_3511 = 35110
	/// 3512 - DC Current Sensor 0-100mA
	case PN_3512 = 35120
	/// 3513 - DC Current Sensor 0-1A
	case PN_3513 = 35130
	/// 3514 - AC Active Power Sensor 0-250V*0-30A (50Hz)
	case PN_3514 = 35140
	/// 3515 - AC Active Power Sensor 0-250V*0-30A (60Hz)
	case PN_3515 = 35150
	/// 3516 - AC Active Power Sensor 0-250V*0-5A (50Hz)
	case PN_3516 = 35160
	/// 3517 - AC Active Power Sensor 0-250V*0-5A (60Hz)
	case PN_3517 = 35170
	/// 3518 - AC Active Power Sensor 0-110V*0-5A (60Hz)
	case PN_3518 = 35180
	/// 3519 - AC Active Power Sensor 0-110V*0-15A (60Hz)
	case PN_3519 = 35190
	/// 3584 - 0-50A DC Current Transducer
	case PN_3584 = 35840
	/// 3585 - 0-100A DC Current Transducer
	case PN_3585 = 35850
	/// 3586 - 0-250A DC Current Transducer
	case PN_3586 = 35860
	/// 3587 - +-50A DC Current Transducer
	case PN_3587 = 35870
	/// 3588 - +-100A DC Current Transducer
	case PN_3588 = 35880
	/// 3589 - +-250A DC Current Transducer
	case PN_3589 = 35890
	/// MOT2002 - Motion Sensor Low Sensitivity
	case PN_MOT2002_LOW = 20020
	/// MOT2002 - Motion Sensor Medium Sensitivity
	case PN_MOT2002_MED = 20021
	/// MOT2002 - Motion Sensor High Sensitivity
	case PN_MOT2002_HIGH = 20022
	/// VCP4114 - +-25A DC Current Transducer
	case PN_VCP4114 = 41140
	/// VCP4115 - +-75A DC Current Transducer
	case PN_VCP4115 = 41150
}
/**
The protocol used to encode the tag data
*/
public enum RFIDProtocol: UInt32 {
	/// EM4100 Series
	case EM4100 = 1
	/// ISO11785 FDX B
	case ISO11785_FDX_B = 2
	/// PhidgetTAG
	case phidgetTAG = 3
	/// HID Generic
	case HID_Generic = 4
	/// HID H10301
	case HID_H10301 = 5
}
/**
The chipset of the writable tag
*/
public enum RFIDChipset: UInt32 {
	/// T5577
	case T5577 = 1
	/// EM4305
	case EM4305 = 2
}
/**
The GPS time in UTC
*/
public struct GPSTime {
	/// Milliseconds
	public var millisecond: Int16
	/// Seconds
	public var second: Int16
	/// Minutes
	public var minute: Int16
	/// Hours
	public var hour: Int16

	public init(
		millisecond: Int16,
		second: Int16,
		minute: Int16,
		hour: Int16
	) {
		self.millisecond = millisecond
		self.second = second
		self.minute = minute
		self.hour = hour
	}

	internal init(_ cstruct: PhidgetGPS_Time) {
		millisecond = cstruct.tm_ms
		second = cstruct.tm_sec
		minute = cstruct.tm_min
		hour = cstruct.tm_hour
	}
	internal var cstruct: PhidgetGPS_Time {
		get {
			var cstruct: PhidgetGPS_Time = PhidgetGPS_Time()
			cstruct.tm_ms = Int16(millisecond)
			cstruct.tm_sec = Int16(second)
			cstruct.tm_min = Int16(minute)
			cstruct.tm_hour = Int16(hour)
			return cstruct
		}
	}
}
/**
GPS Date in UTC
*/
public struct GPSDate {
	/// Day (1-31)
	public var day: Int16
	/// Month (1-12)
	public var month: Int16
	/// Year
	public var year: Int16

	public init(
		day: Int16,
		month: Int16,
		year: Int16
	) {
		self.day = day
		self.month = month
		self.year = year
	}

	internal init(_ cstruct: PhidgetGPS_Date) {
		day = cstruct.tm_mday
		month = cstruct.tm_mon
		year = cstruct.tm_year
	}
	internal var cstruct: PhidgetGPS_Date {
		get {
			var cstruct: PhidgetGPS_Date = PhidgetGPS_Date()
			cstruct.tm_mday = Int16(day)
			cstruct.tm_mon = Int16(month)
			cstruct.tm_year = Int16(year)
			return cstruct
		}
	}
}
/**
NMEA GGA Sentence
*/
public struct GPGGA {
	/// Latitude
	public var latitude: Double
	/// Longitude
	public var longitude: Double
	/// GPS quality indicator
	public var fixQuality: Int16
	/// Number of satellites in use
	public var numSatellites: Int16
	/// Horizontal dilution of precision
	public var horizontalDilution: Double
	/// Mean sea level altitude
	public var altitude: Double
	/// Geoidal separation
	public var heightOfGeoid: Double

	public init(
		latitude: Double,
		longitude: Double,
		fixQuality: Int16,
		numSatellites: Int16,
		horizontalDilution: Double,
		altitude: Double,
		heightOfGeoid: Double
	) {
		self.latitude = latitude
		self.longitude = longitude
		self.fixQuality = fixQuality
		self.numSatellites = numSatellites
		self.horizontalDilution = horizontalDilution
		self.altitude = altitude
		self.heightOfGeoid = heightOfGeoid
	}

	internal init(_ cstruct: PhidgetGPS_GPGGA) {
		latitude = cstruct.latitude
		longitude = cstruct.longitude
		fixQuality = cstruct.fixQuality
		numSatellites = cstruct.numSatellites
		horizontalDilution = cstruct.horizontalDilution
		altitude = cstruct.altitude
		heightOfGeoid = cstruct.heightOfGeoid
	}
	internal var cstruct: PhidgetGPS_GPGGA {
		get {
			var cstruct: PhidgetGPS_GPGGA = PhidgetGPS_GPGGA()
			cstruct.latitude = Double(latitude)
			cstruct.longitude = Double(longitude)
			cstruct.fixQuality = Int16(fixQuality)
			cstruct.numSatellites = Int16(numSatellites)
			cstruct.horizontalDilution = Double(horizontalDilution)
			cstruct.altitude = Double(altitude)
			cstruct.heightOfGeoid = Double(heightOfGeoid)
			return cstruct
		}
	}
}
/**
NMEA GSA sentence
*/
public struct GPGSA {
	/// Manual/Automatic mode (A = auto, M = manual)
	public var mode: CChar
	/// Fix type (1 = no fix, 2 = 2D, 3 = 3D)
	public var fixType: Int16
	/// Satellite IDs
	public var satUsed: [Int16]
	/// Position dilution of precision
	public var positionDilution: Double
	/// Horizontal dilution of precision
	public var horizontalDilution: Double
	/// Vertical dilution of precision
	public var verticalDilution: Double

	public init(
		mode: CChar,
		fixType: Int16,
		satUsed: [Int16],
		positionDilution: Double,
		horizontalDilution: Double,
		verticalDilution: Double
	) {
		self.mode = mode
		self.fixType = fixType
		self.satUsed = satUsed
		self.positionDilution = positionDilution
		self.horizontalDilution = horizontalDilution
		self.verticalDilution = verticalDilution
	}

	internal init(_ cstruct: PhidgetGPS_GPGSA) {
		mode = cstruct.mode
		fixType = cstruct.fixType
		let satUsedTmp = cstruct.satUsed
		satUsed = [satUsedTmp.0, satUsedTmp.1, satUsedTmp.2, satUsedTmp.3, satUsedTmp.4, satUsedTmp.5, satUsedTmp.6, satUsedTmp.7, satUsedTmp.8, satUsedTmp.9, satUsedTmp.10, satUsedTmp.11]
		positionDilution = cstruct.posnDilution
		horizontalDilution = cstruct.horizDilution
		verticalDilution = cstruct.vertDilution
	}
	internal var cstruct: PhidgetGPS_GPGSA {
		get {
			var cstruct: PhidgetGPS_GPGSA = PhidgetGPS_GPGSA()
			cstruct.mode = CChar(mode)
			cstruct.fixType = Int16(fixType)
			precondition(satUsed.count <= 12, "satUsed array must have at most 12 elements")
			memcpy(&cstruct.satUsed, satUsed, satUsed.count * MemoryLayout<Int16>.size)
			cstruct.posnDilution = Double(positionDilution)
			cstruct.horizDilution = Double(horizontalDilution)
			cstruct.vertDilution = Double(verticalDilution)
			return cstruct
		}
	}
}
/**
NMEA RMC sentence
*/
public struct GPRMC {
	/// Status of the data
	public var status: CChar
	/// Latitude
	public var latitude: Double
	/// Longitude
	public var longitude: Double
	/// Speed over ground in knots
	public var speedKnots: Double
	/// Heading over ground in degrees
	public var heading: Double
	/// Magnetic variation
	public var magneticVariation: Double
	/// Mode indicator
	public var mode: CChar

	public init(
		status: CChar,
		latitude: Double,
		longitude: Double,
		speedKnots: Double,
		heading: Double,
		magneticVariation: Double,
		mode: CChar
	) {
		self.status = status
		self.latitude = latitude
		self.longitude = longitude
		self.speedKnots = speedKnots
		self.heading = heading
		self.magneticVariation = magneticVariation
		self.mode = mode
	}

	internal init(_ cstruct: PhidgetGPS_GPRMC) {
		status = cstruct.status
		latitude = cstruct.latitude
		longitude = cstruct.longitude
		speedKnots = cstruct.speedKnots
		heading = cstruct.heading
		magneticVariation = cstruct.magneticVariation
		mode = cstruct.mode
	}
	internal var cstruct: PhidgetGPS_GPRMC {
		get {
			var cstruct: PhidgetGPS_GPRMC = PhidgetGPS_GPRMC()
			cstruct.status = CChar(status)
			cstruct.latitude = Double(latitude)
			cstruct.longitude = Double(longitude)
			cstruct.speedKnots = Double(speedKnots)
			cstruct.heading = Double(heading)
			cstruct.magneticVariation = Double(magneticVariation)
			cstruct.mode = CChar(mode)
			return cstruct
		}
	}
}
/**
NMEA VTG sentence
*/
public struct GPVTG {
	/// True heading over ground
	public var trueHeading: Double
	/// Magnetic heading
	public var magneticHeading: Double
	/// Speed over ground in knots
	public var speedKnots: Double
	/// Speed over ground in km/h
	public var speed: Double
	/// Mode indicator
	public var mode: CChar

	public init(
		trueHeading: Double,
		magneticHeading: Double,
		speedKnots: Double,
		speed: Double,
		mode: CChar
	) {
		self.trueHeading = trueHeading
		self.magneticHeading = magneticHeading
		self.speedKnots = speedKnots
		self.speed = speed
		self.mode = mode
	}

	internal init(_ cstruct: PhidgetGPS_GPVTG) {
		trueHeading = cstruct.trueHeading
		magneticHeading = cstruct.magneticHeading
		speedKnots = cstruct.speedKnots
		speed = cstruct.speed
		mode = cstruct.mode
	}
	internal var cstruct: PhidgetGPS_GPVTG {
		get {
			var cstruct: PhidgetGPS_GPVTG = PhidgetGPS_GPVTG()
			cstruct.trueHeading = Double(trueHeading)
			cstruct.magneticHeading = Double(magneticHeading)
			cstruct.speedKnots = Double(speedKnots)
			cstruct.speed = Double(speed)
			cstruct.mode = CChar(mode)
			return cstruct
		}
	}
}
/**
The NMEA Data structure
*/
public struct NMEAData {
	/// NMEA GGA Sentence
	public var GGA: GPGGA
	/// NMEA GSA Sentence
	public var GSA: GPGSA
	/// NMEA RMC Sentence
	public var RMC: GPRMC
	/// NMEA VTG Sentence
	public var VTG: GPVTG

	public init(
		GGA: GPGGA,
		GSA: GPGSA,
		RMC: GPRMC,
		VTG: GPVTG
	) {
		self.GGA = GGA
		self.GSA = GSA
		self.RMC = RMC
		self.VTG = VTG
	}

	internal init(_ cstruct: PhidgetGPS_NMEAData) {
		GGA = GPGGA(cstruct.GGA)
		GSA = GPGSA(cstruct.GSA)
		RMC = GPRMC(cstruct.RMC)
		VTG = GPVTG(cstruct.VTG)
	}
	internal var cstruct: PhidgetGPS_NMEAData {
		get {
			var cstruct: PhidgetGPS_NMEAData = PhidgetGPS_NMEAData()
			cstruct.GGA = GGA.cstruct
			cstruct.GSA = GSA.cstruct
			cstruct.RMC = RMC.cstruct
			cstruct.VTG = VTG.cstruct
			return cstruct
		}
	}
}
/**
Controls the AHRS algorithm.
*/
public enum SpatialAlgorithm: UInt32 {
	/// No AHRS algorithm is used.
	case none = 0
	/// AHRS algorithm, incorporating magnetometer data for yaw correction.
	case AHRS = 1
	/// IMU algorithm, using gyro and accelerometer, but not magnetometer.
	case IMU = 2
}
/**
A quaternion from a PhidgetSpatial
*/
public struct SpatialQuaternion {
	/// The x component of the quaternion
	public var x: Double
	/// The y component of the quaternion
	public var y: Double
	/// The z component of the quaternion
	public var z: Double
	/// The W component of the quaternion
	public var w: Double

	public init(
		x: Double,
		y: Double,
		z: Double,
		w: Double
	) {
		self.x = x
		self.y = y
		self.z = z
		self.w = w
	}

	internal init(_ cstruct: PhidgetSpatial_SpatialQuaternion) {
		x = cstruct.x
		y = cstruct.y
		z = cstruct.z
		w = cstruct.w
	}
	internal var cstruct: PhidgetSpatial_SpatialQuaternion {
		get {
			var cstruct: PhidgetSpatial_SpatialQuaternion = PhidgetSpatial_SpatialQuaternion()
			cstruct.x = Double(x)
			cstruct.y = Double(y)
			cstruct.z = Double(z)
			cstruct.w = Double(w)
			return cstruct
		}
	}
}
/**
A set of Euler Angles from a PhidgetSpatial
*/
public struct SpatialEulerAngles {
	/// The pitch angle, in degrees
	public var pitch: Double
	/// The roll angle, in degrees
	public var roll: Double
	/// The heading angle, in degrees
	public var heading: Double

	public init(
		pitch: Double,
		roll: Double,
		heading: Double
	) {
		self.pitch = pitch
		self.roll = roll
		self.heading = heading
	}

	internal init(_ cstruct: PhidgetSpatial_SpatialEulerAngles) {
		pitch = cstruct.pitch
		roll = cstruct.roll
		heading = cstruct.heading
	}
	internal var cstruct: PhidgetSpatial_SpatialEulerAngles {
		get {
			var cstruct: PhidgetSpatial_SpatialEulerAngles = PhidgetSpatial_SpatialEulerAngles()
			cstruct.pitch = Double(pitch)
			cstruct.roll = Double(roll)
			cstruct.heading = Double(heading)
			return cstruct
		}
	}
}
/**
RTD sensor type
*/
public enum RTDType: UInt32 {
	/// Configures the RTD type as a PT100 with a 3850ppm curve.
	case PT100_3850 = 1
	/// Configures the RTD type as a PT1000 with a 3850ppm curve.
	case PT1000_3850 = 2
	/// Configures the RTD type as a PT100 with a 3920ppm curve.
	case PT100_3920 = 3
	/// Configures the RTD type as a PT1000 with a 3920ppm curve.
	case PT1000_3920 = 4
}
/**
The type of thermocouple being used
*/
public enum ThermocoupleType: UInt32 {
	/// Configures the thermocouple input as a J-Type thermocouple.
	case J = 1
	/// Configures the thermocouple input as a K-Type thermocouple.
	case K = 2
	/// Configures the thermocouple input as a E-Type thermocouple.
	case E = 3
	/// Configures the thermocouple input as a T-Type thermocouple.
	case T = 4
}
/**
Type of filter used on the frequency input
*/
public enum FrequencyFilterType: UInt32 {
	/// Frequency is calculated from the number of times the signal transitions from a negative voltage to a positive voltage and back again.
	case zeroCrossing = 1
	/// Frequency is calculated from the number of times the signal transitions from a logic false to a logic true and back again.
	case logicLevel = 2
}
/**
Describes the encoding technique used for the code
*/
public enum IRCodeEncoding: UInt32 {
	/// Unknown - the default value
	case unknown = 1
	/// Space encoding, or Pulse Distance Modulation
	case space = 2
	/// Pulse encoding, or Pulse Width Modulation
	case pulse = 3
	/// Bi-Phase, or Manchester encoding
	case biPhase = 4
	/// RC5 - a type of Bi-Phase encoding
	case RC5 = 5
	/// RC6 - a type of Bi-Phase encoding
	case RC6 = 6
}
/**
The length type of the bitstream and gaps
*/
public enum IRCodeLength: UInt32 {
	/// Unknown - the default value
	case unknown = 1
	/// Constant - the bitstream and gap length is constant
	case constant = 2
	/// Variable - the bitstream has a variable length with a constant gap
	case variable = 3
}
/**
The PhidgetIR CodeInfo structure contains all information needed to transmit a code, apart from the actual code data.

*   Some values can be set to null to select defaults.
*/
public struct IRCodeInfo {
	/// Number of bits in the code
	public var bitCount: UInt32
	/// Encoding technique used to encode the data
	public var encoding: IRCodeEncoding
	/// Constant or Variable length encoding
	public var length: IRCodeLength
	/// Gap time in microseconds
	public var gap: UInt32
	/// Trail time in microseconds. Can be zero for no trail
	public var trail: UInt32
	/// Header pulse and space. Can be zero for no header
	public var header: [UInt32]
	/// Pulse and Space times to represent a '1' bit, in microseconds
	public var one: [UInt32]
	/// Pulse and Space times to represent a '0' bit, in microseconds
	public var zero: [UInt32]
	/// A series or pulse and space times to represent the repeat code. Start and end with pulses and null terminate. Set to 0 for none.
	public var repeatCode: [UInt32]
	/// Minium number of times to repeat a code on transmit
	public var minRepeat: UInt32
	/// Duty Cycle in percent (0.1-0.5). Defaults to 0.33
	public var dutyCycle: Double
	/// Carrier frequency in Hz - defaults to 38kHz
	public var carrierFrequency: UInt32
	/// Bit toggles, which are applied to the code after each transmit
	public var toggleMask: String

	public init(
		bitCount: UInt32,
		encoding: IRCodeEncoding,
		length: IRCodeLength,
		gap: UInt32,
		trail: UInt32,
		header: [UInt32],
		one: [UInt32],
		zero: [UInt32],
		repeatCode: [UInt32],
		minRepeat: UInt32,
		dutyCycle: Double,
		carrierFrequency: UInt32,
		toggleMask: String
	) {
		self.bitCount = bitCount
		self.encoding = encoding
		self.length = length
		self.gap = gap
		self.trail = trail
		self.header = header
		self.one = one
		self.zero = zero
		self.repeatCode = repeatCode
		self.minRepeat = minRepeat
		self.dutyCycle = dutyCycle
		self.carrierFrequency = carrierFrequency
		self.toggleMask = toggleMask
	}

	internal init(_ cstruct: PhidgetIR_CodeInfo) {
		bitCount = cstruct.bitCount
		encoding = IRCodeEncoding(rawValue: cstruct.encoding.rawValue)!
		length = IRCodeLength(rawValue: cstruct.length.rawValue)!
		gap = cstruct.gap
		trail = cstruct.trail
		let headerTmp = cstruct.header
		header = [headerTmp.0, headerTmp.1]
		let oneTmp = cstruct.one
		one = [oneTmp.0, oneTmp.1]
		let zeroTmp = cstruct.zero
		zero = [zeroTmp.0, zeroTmp.1]
		let repeatCodeTmp = cstruct.repeat
		repeatCode = [repeatCodeTmp.0, repeatCodeTmp.1, repeatCodeTmp.2, repeatCodeTmp.3, repeatCodeTmp.4, repeatCodeTmp.5, repeatCodeTmp.6, repeatCodeTmp.7, repeatCodeTmp.8, repeatCodeTmp.9, repeatCodeTmp.10, repeatCodeTmp.11, repeatCodeTmp.12, repeatCodeTmp.13, repeatCodeTmp.14, repeatCodeTmp.15, repeatCodeTmp.16, repeatCodeTmp.17, repeatCodeTmp.18, repeatCodeTmp.19, repeatCodeTmp.20, repeatCodeTmp.21, repeatCodeTmp.22, repeatCodeTmp.23, repeatCodeTmp.24, repeatCodeTmp.25]
		minRepeat = cstruct.minRepeat
		dutyCycle = cstruct.dutyCycle
		carrierFrequency = cstruct.carrierFrequency
		let toggleMaskTmp = cstruct.toggleMask
        toggleMask = "\(toggleMaskTmp.0))"
	}
	internal var cstruct: PhidgetIR_CodeInfo {
		get {
			var cstruct: PhidgetIR_CodeInfo = PhidgetIR_CodeInfo()
			cstruct.bitCount = UInt32(bitCount)
			cstruct.encoding = PhidgetIR_Encoding(encoding.rawValue)
			cstruct.length = PhidgetIR_Length(length.rawValue)
			cstruct.gap = UInt32(gap)
			cstruct.trail = UInt32(trail)
			precondition(header.count <= 2, "header array must have at most 2 elements")
			memcpy(&cstruct.header, header, header.count * MemoryLayout<UInt32>.size)
			precondition(one.count <= 2, "one array must have at most 2 elements")
			memcpy(&cstruct.one, one, one.count * MemoryLayout<UInt32>.size)
			precondition(zero.count <= 2, "zero array must have at most 2 elements")
			memcpy(&cstruct.zero, zero, zero.count * MemoryLayout<UInt32>.size)
			precondition(repeatCode.count <= 26, "repeatCode array must have at most 26 elements")
			memcpy(&cstruct.repeat, repeatCode, repeatCode.count * MemoryLayout<UInt32>.size)
			cstruct.minRepeat = UInt32(minRepeat)
			cstruct.dutyCycle = Double(dutyCycle)
			cstruct.carrierFrequency = UInt32(carrierFrequency)
			let toggleMaskTmp = Array(toggleMask.utf8)
			precondition(toggleMaskTmp.count <= 33, "toggleMask must have at most 33 characters")
			memcpy(&cstruct.toggleMask, toggleMaskTmp, toggleMaskTmp.count)
			return cstruct
		}
	}
}
/**
Method of motor control
*/
public enum StepperControlMode: UInt32 {
	/// Control the motor by setting a target position.
	case step = 0
	/// Control the motor by selecting a target velocity (sign indicates direction). The motor will rotate continuously in the chosen direction.
	case run = 1
}
/**
The type of font being used
*/
public enum LCDFont: UInt32 {
	/// User-defined font #1
	case user1 = 1
	/// User-defined font #2
	case user2 = 2
	/// 6px by 10px font
	case dimensions_6x10 = 3
	/// 5px by 8px font
	case dimensions_5x8 = 4
	/// 6px by 12px font
	case dimensions_6x12 = 5
}
/**
Size of the attached LCD screen
*/
public enum LCDScreenSize: UInt32 {
	/// Screen size unknown
	case noScreen = 1
	/// One row, eight column text screen
	case dimensions_1x8 = 2
	/// Two row, eight column text screen
	case dimensions_2x8 = 3
	/// One row, 16 column text screen
	case dimensions_1x16 = 4
	/// Two row, 16 column text screen
	case dimensions_2x16 = 5
	/// Four row, 16 column text screen
	case dimensions_4x16 = 6
	/// Two row, 20 column text screen
	case dimensions_2x20 = 7
	/// Four row, 20 column text screen.
	case dimensions_4x20 = 8
	/// Two row, 24 column text screen
	case dimensions_2x24 = 9
	/// One row, 40 column text screen
	case dimensions_1x40 = 10
	/// Two row, 40 column text screen
	case dimensions_2x40 = 11
	/// Four row, 40 column text screen
	case dimensions_4x40 = 12
	/// 64px by 128px graphic screen
	case dimensions_64x128 = 13
}
/**
The on/off state of the pixel to be set
*/
public enum LCDPixelState: UInt32 {
	/// Pixel off state
	case off = 0
	/// Pixel on state
	case on = 1
	/// Invert the pixel state
	case invert = 2
}
/**
The SPI Mode
*/
public enum DataAdapterSPIMode: UInt32 {
	/// CPOL = 0 CPHA = 0
	case mode_0 = 1
	/// CPOL = 0 CPHA = 1
	case mode_1 = 2
	/// CPOL = 1 CPHA = 0
	case mode_2 = 3
	/// CPOL = 1 CPHA = 1
	case mode_3 = 4
}
/**
The communication frequency
*/
public enum DataAdapterFrequency: UInt32 {
	/// 10kHz communication frequency
	case frequency_10kHz = 1
	/// 100kHz communication frequency
	case frequency_100kHz = 2
	/// 400kHz communication frequency
	case frequency_400kHz = 3
	/// 187.5kHz communication frequency
	case frequency_188kHz = 4
	/// 375kHz communication frequency
	case frequency_375kHz = 5
	/// 750kHz communication frequency
	case frequency_750kHz = 6
	/// 1500kHz communication frequency
	case frequency_1500kHz = 7
	/// 3MHz communication frequency
	case frequency_3MHz = 8
	/// 6MHz communication frequency
	case frequency_6MHz = 9
}
/**
The Type of Error on the Packet
*/
public enum PacketErrorCode: UInt32 {
	/// No error
	case ok = 0
	/// Unknown Error
	case unknown = 1
	/// The response packet timed out
	case timeout = 2
	/// Something about the sent or received data didn't match the expected format.
	case format = 3
	/// The input lines are invalid. This likely means a cable has been unplugged.
	case invalid = 4
	/// Data is being received faster than it can be processed. Some has been lost.
	case overrun = 5
	/// Something behind the scenes got out of sequence.
	case corrupt = 6
	/// One or more packets have received a NACK response
	case NACK = 7
}
/**
The SPI Chip Select
*/
public enum DataAdapterSPIChipSelect: UInt32 {
	/// CS normally HIGH, Automatically goes LOW during transmission
	case activeLow = 1
	/// CS normally LOW, Automatically goes HIGH during transmission
	case activeHigh = 2
	/// CS is held LOW as long as this is set
	case low = 3
	/// CS is held HIGH as long as this is set
	case high = 4
}
/**
The endianness of data being transmitted
*/
public enum DataAdapterEndianness: UInt32 {
	/// MSB First
	case MSB_First = 1
	/// LSB First
	case LSB_First = 2
}
/**
LED color values (RGBW - Red, Green, Blue, White)
*/
public struct LEDArrayColor {
	/// Red Value
	public var r: UInt8
	/// Green Value
	public var g: UInt8
	/// Blue Value
	public var b: UInt8
	/// White Value (application dependent)
	public var w: UInt8

	public init(
		r: UInt8,
		g: UInt8,
		b: UInt8,
		w: UInt8
	) {
		self.r = r
		self.g = g
		self.b = b
		self.w = w
	}

	internal init(_ cstruct: PhidgetLEDArray_Color) {
		r = cstruct.r
		g = cstruct.g
		b = cstruct.b
		w = cstruct.w
	}
	internal var cstruct: PhidgetLEDArray_Color {
		get {
			var cstruct: PhidgetLEDArray_Color = PhidgetLEDArray_Color()
			cstruct.r = UInt8(r)
			cstruct.g = UInt8(g)
			cstruct.b = UInt8(b)
			cstruct.w = UInt8(w)
			return cstruct
		}
	}
}
/**
The order that color information is to be sent to the LEDs
*/
public enum LEDArrayColorOrder: UInt32 {
	/// Byte order RGB (WS2811)
	case RGB = 1
	/// Byte order GRB (WS2812B, SK6812)
	case GRB = 2
	/// Byte order RGBW
	case RGBW = 3
	/// Byte order GRBW (SK6812RGBW)
	case GRBW = 4
}
/**
The animation type
*/
public enum LEDArrayAnimationType: UInt32 {
	/// Move the pattern in a positively incrementing direction
	case forwardScroll = 1
	/// Move the pattern in a decrementing direction
	case reverseScroll = 2
	/// Fades LEDs between colors in the supplied pattern, chosen at random.
	case randomize = 3
	/// Flip the pattern and move it in a positively incrementing direction, starting from the animation end point
	case forwardScrollMirror = 4
	/// Flip the pattern and move it in a decrementing direction, starting from the animation end point
	case reverseScrollMirror = 5
}
/**
LED animation description
*/
public struct LEDArrayAnimation {
	/// Which LED to start the animation from
	public var startAddress: UInt32
	/// Which LED the animation will end on
	public var endAddress: UInt32
	/// Time between changes in ms
	public var time: UInt32
	/// The type of animation
	public var animationType: LEDArrayAnimationType

	public init(
		startAddress: UInt32,
		endAddress: UInt32,
		time: UInt32,
		animationType: LEDArrayAnimationType
	) {
		self.startAddress = startAddress
		self.endAddress = endAddress
		self.time = time
		self.animationType = animationType
	}

	internal init(_ cstruct: PhidgetLEDArray_Animation) {
		startAddress = cstruct.startAddress
		endAddress = cstruct.endAddress
		time = cstruct.time
		animationType = LEDArrayAnimationType(rawValue: cstruct.animationType.rawValue)!
	}
	internal var cstruct: PhidgetLEDArray_Animation {
		get {
			var cstruct: PhidgetLEDArray_Animation = PhidgetLEDArray_Animation()
			cstruct.startAddress = UInt32(startAddress)
			cstruct.endAddress = UInt32(endAddress)
			cstruct.time = UInt32(time)
			cstruct.animationType = PhidgetLEDArray_AnimationType(animationType.rawValue)
			return cstruct
		}
	}
}
/**
The measurement range of the sound sensor
*/
public enum SPLRange: UInt32 {
	/// Range 102dB
	case dB_102 = 1
	/// Range 82dB
	case dB_82 = 2
}
/**
The mode of the VINT port
*/
public enum HubPortMode: UInt32 {
	/// Communicate with a smart VINT device
	case VINT = 0
	/// 5V Logic-level digital input
	case digitalInput = 1
	/// 3.3V digital output
	case digitalOutput = 2
	/// 0-5V voltage input for non-ratiometric sensors 
	case voltageInput = 3
	/// 0-5V voltage input for ratiometric sensors
	case voltageRatioInput = 4
}
