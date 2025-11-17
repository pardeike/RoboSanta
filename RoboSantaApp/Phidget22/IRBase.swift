import Foundation
//import Phidget22

/**
The Infrared Remote class lets you read and transmit command codes from infrared remotes that the majority of household appliances use. You can use this class to construct and transmit commands from scratch, or learn and retransmit codes from the remote controller of your appliance.
*/
public class IRBase : Phidget {

	public init() {
		var h: PhidgetHandle?
		PhidgetIR_create(&h)
		super.init(h!)
		initializeEvents()
	}

	internal override init(_ handle: PhidgetHandle) {
		super.init(handle)
	}

    @MainActor deinit {
		if (retained) {
			Phidget_release(&chandle)
		} else {
			uninitializeEvents()
			PhidgetIR_delete(&chandle)
		}
	}
	/**
	The value for a long space in raw data
	*/
	public static let rawDataLongSpace: UInt32 = 4294967295
	/**
	Maximum bit count for sent / received data
	*/
	public static let maxCodeBitCount: Int = 128
	/**
	Maximum bit count for sent / received data
	*/
	public static let maxCodeStringLength: Int = 33

	/**
	The last code the channel has received.

	*   The code is represented by a hexadecimal string (array of bytes).

	- returns:
		- code: The last received code
		- bitCount: length of the received code in bits

	- throws:
	An error or type `PhidgetError`
	*/
	public func getLastCode() throws -> (code: String, bitCount: UInt32) {
		let result: PhidgetReturnCode
		let code: UnsafeMutablePointer<CChar> = UnsafeMutablePointer<CChar>.allocate(capacity: 33)
		let codeLen: Int = 33
		var bitCount: UInt32 = 0
		result = PhidgetIR_getLastCode(chandle, code, codeLen, &bitCount)
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
		let codeSwift = String(cString: code)
		code.deallocate()
		return (code: codeSwift, bitCount: bitCount)
	}

	/**
	The last code the channel has learned.

	*   The code is represented by a hexadecimal string (array of bytes).
	*   The `codeInfo` structure holds data that describes the learned code.

	- returns:
		- code: The last learned code
		- codeInfo: contains the data for characterizing the code

	- throws:
	An error or type `PhidgetError`
	*/
	public func getLastLearnedCode() throws -> (code: String, codeInfo: IRCodeInfo) {
		let result: PhidgetReturnCode
		let code: UnsafeMutablePointer<CChar> = UnsafeMutablePointer<CChar>.allocate(capacity: 33)
		let codeLen: Int = 33
		var codeInfo: PhidgetIR_CodeInfo = PhidgetIR_CodeInfo()
		result = PhidgetIR_getLastLearnedCode(chandle, code, codeLen, &codeInfo)
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
		let codeSwift = String(cString: code)
		code.deallocate()
		return (code: codeSwift, codeInfo: IRCodeInfo(codeInfo))
	}

	/**
	Transmits a code

	*   `code` data is transmitted MSBit first.
	*   MSByte is in array index 0 of `code`
	*   LSBit is right justified, therefore, MSBit may be in bit position 0-7 (of array index 0) depending on the bit count.

	- throws:
	An error or type `PhidgetError`

	- parameters:
		- code: code data
		- codeInfo: contains the data for characterizing the code.
	*/
	public func transmit(code: String, codeInfo: IRCodeInfo) throws {
		let result: PhidgetReturnCode
		var codeInfoTmp = codeInfo.cstruct
		result = PhidgetIR_transmit(chandle, code, &codeInfoTmp)
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
	}

	/**
	Transmits **raw** data as a series of pulses and spaces.

	*   `data` must start and end with a pulse.
	    *   Each element is a positive time in μs
	*   `dataLength` has a maximum length of 200, however, streams should be kept must shorter than this (less than 100ms between gaps).

	*   `dataLength` must be an odd number

	*   Leave `carrierFrequency` as 0 for default.

	*   `carrierFrequency` has a range of 10kHz - 1MHz

	*   Leave `dutyCycle` as 0 for default

	*   `dutyCycle` can have a value between 0.1 and 0.5

	*   Specifying a `gap` will guarantee a gap time (no transmitting) after data is sent.

	*   gap time is in μs
	*   gap time can be set to 0

	- throws:
	An error or type `PhidgetError`

	- parameters:
		- data: data to send.
		- carrierFrequency: carrier frequency in Hz
		- dutyCycle: the duty cycle
		- gap: the gap time.
	*/
	public func transmitRaw(data: [UInt32], carrierFrequency: UInt32, dutyCycle: Double, gap: UInt32) throws {
		let result: PhidgetReturnCode
		let dataLen: Int = data.count
		result = PhidgetIR_transmitRaw(chandle, data, dataLen, carrierFrequency, dutyCycle, gap)
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
	}

	/**
	Transmits a repeat of the last transmited code.

	*   Depending on the CodeInfo structure, this may be a retransmission of the code itself, or there may be a special repeat code.

	- throws:
	An error or type `PhidgetError`
	*/
	public func transmitRepeat() throws {
		let result: PhidgetReturnCode
		result = PhidgetIR_transmitRepeat(chandle)
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
	}

	internal override func initializeEvents() {
		initializeBaseEvents()
		PhidgetIR_setOnCodeHandler(chandle, nativeCodeHandler, UnsafeMutableRawPointer(selfCtx!.toOpaque()))
		PhidgetIR_setOnLearnHandler(chandle, nativeLearnHandler, UnsafeMutableRawPointer(selfCtx!.toOpaque()))
		PhidgetIR_setOnRawDataHandler(chandle, nativeRawDataHandler, UnsafeMutableRawPointer(selfCtx!.toOpaque()))
	}

	internal override func uninitializeEvents() {
		uninitializeBaseEvents()
		PhidgetIR_setOnCodeHandler(chandle, nil, nil)
		PhidgetIR_setOnLearnHandler(chandle, nil, nil)
		PhidgetIR_setOnRawDataHandler(chandle, nil, nil)
	}

	/**
	This event is fired every time a code is received and correctly decoded.

	*   The code is represented by a hexadecimal string (array of bytes) with a length of 1/4 of `bitCount`.
	*   The MSBit is considered to be the first bit received and will be in array index 0 of `code`
	*   Repeat will be true if a repeat is detected (either timing wise or via a repeat code)

	*   False repeasts can happen if two separate button presses happen close together

	---
	## Parameters:
	*   `code`: The code string
	*   `bitCount`: The length of the received code in bits
	*   `isRepeat`: 'true' if a repeat is detected
	*/
	public let code = Event<IR, (code: String, bitCount: UInt32, isRepeat: Bool)> ()
	let nativeCodeHandler : PhidgetIR_OnCodeCallback = { ch, ctx, code, bitCount, isRepeat in
		let me = Unmanaged<IR>.fromOpaque(ctx!).takeUnretainedValue()
		me.code.raise(me, (String(cString: code!), bitCount, (isRepeat == 0 ? false : true)));
	}

	/**
	This event fires when a button has been held down long enough for the channel to have learned the CodeInfo values

	*   A code is usually learned after 1 second, or after 4 repeats.

	---
	## Parameters:
	*   `code`: The code string
	*   `codeInfo`: Contains the data for characterizing the code.
	*/
	public let learn = Event<IR, (code: String, codeInfo: IRCodeInfo)> ()
	let nativeLearnHandler : PhidgetIR_OnLearnCallback = { ch, ctx, code, codeInfo in
		let me = Unmanaged<IR>.fromOpaque(ctx!).takeUnretainedValue()
		me.learn.raise(me, (String(cString: code!), IRCodeInfo(codeInfo!.pointee)));
	}

	/**
	This event will fire every time the channel gets more data

	*   This will happen at most once every 8ms.

	---
	## Parameters:
	*   `data`: The data being received
	*/
	public let rawData = Event<IR, [UInt32]> ()
	let nativeRawDataHandler : PhidgetIR_OnRawDataCallback = { ch, ctx, data, dataLen in
		let me = Unmanaged<IR>.fromOpaque(ctx!).takeUnretainedValue()
		me.rawData.raise(me, [UInt32](UnsafeBufferPointer(start: data!, count: dataLen)));
	}

}
