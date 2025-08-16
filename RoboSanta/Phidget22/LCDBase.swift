import Foundation
//import Phidget22

/**
The LCD class allows you to control various liquid crystal displays. It offers control of displayed text as well as screen settings and custom character creation.
*/
public class LCDBase : Phidget {

	public init() {
		var h: PhidgetHandle?
		PhidgetLCD_create(&h)
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
			PhidgetLCD_delete(&chandle)
		}
	}

	/**
	Set to true to automatically flush the LCD screen after every message that writes to the LCD.

	- returns:
	Allows setting the LCD to flush the screen automatically

	- throws:
	An error or type `PhidgetError`
	*/
	public func getAutoFlush() throws -> Bool {
		let result: PhidgetReturnCode
		var autoFlush: Int32 = 0
		result = PhidgetLCD_getAutoFlush(chandle, &autoFlush)
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
		return (autoFlush == 0 ? false : true)
	}

	/**
	Set to true to automatically flush the LCD screen after every message that writes to the LCD.

	- throws:
	An error or type `PhidgetError`

	- parameters:
		- autoFlush: Allows setting the LCD to flush the screen automatically
	*/
	public func setAutoFlush(_ autoFlush: Bool) throws {
		let result: PhidgetReturnCode
		result = PhidgetLCD_setAutoFlush(chandle, (autoFlush ? 1 : 0))
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
	}

	/**
	The `Backlight` affects the brightness of the LCD screen.

	*   `Backlight` is bounded by `MinBacklight` and `MaxBacklight`.

	- returns:
	The backlight value

	- throws:
	An error or type `PhidgetError`
	*/
	public func getBacklight() throws -> Double {
		let result: PhidgetReturnCode
		var backlight: Double = 0
		result = PhidgetLCD_getBacklight(chandle, &backlight)
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
		return backlight
	}

	/**
	The `Backlight` affects the brightness of the LCD screen.

	*   `Backlight` is bounded by `MinBacklight` and `MaxBacklight`.

	- throws:
	An error or type `PhidgetError`

	- parameters:
		- backlight: The backlight value
	*/
	public func setBacklight(_ backlight: Double) throws {
		let result: PhidgetReturnCode
		result = PhidgetLCD_setBacklight(chandle, backlight)
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
	}

	/**
	The minimum value that `Backlight` can be set to.

	- returns:
	The backlight value

	- throws:
	An error or type `PhidgetError`
	*/
	public func getMinBacklight() throws -> Double {
		let result: PhidgetReturnCode
		var minBacklight: Double = 0
		result = PhidgetLCD_getMinBacklight(chandle, &minBacklight)
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
		return minBacklight
	}

	/**
	The maximum value that `Backlight` can be set to.

	- returns:
	The backlight value

	- throws:
	An error or type `PhidgetError`
	*/
	public func getMaxBacklight() throws -> Double {
		let result: PhidgetReturnCode
		var maxBacklight: Double = 0
		result = PhidgetLCD_getMaxBacklight(chandle, &maxBacklight)
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
		return maxBacklight
	}

	/**
	Create a bitmap and select a character to represent it. Now, when you use the specific character, the bitmap will show in it's place.

	- throws:
	An error or type `PhidgetError`

	- parameters:
		- font: The font the character belongs to
		- character: The character to be changed, in a null-terminated string.
		- bitmap: Bitmap array
	*/
	public func setCharacterBitmap(font: LCDFont, character: String, bitmap: [UInt8]) throws {
		let result: PhidgetReturnCode
		result = PhidgetLCD_setCharacterBitmap(chandle, PhidgetLCD_Font(font.rawValue), character, bitmap)
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
	}

	/**
	Create a bitmap and select a character to represent it. Now, when you use the specific character, the bitmap will show in it's place.

	- parameters:
		- font: The font the character belongs to
		- character: The character to be changed, in a null-terminated string.
		- bitmap: Bitmap array
		- completion: Asynchronous completion callback
	*/
	public func setCharacterBitmap(font: LCDFont, character: String, bitmap: [UInt8], completion: @escaping (ErrorCode) -> ()) {
		let callback = AsyncCallback(completion)
		let callbackCtx = Unmanaged.passRetained(callback)
		PhidgetLCD_setCharacterBitmap_async(chandle, PhidgetLCD_Font(font.rawValue), character, bitmap, AsyncCallback.nativeAsyncCallback, UnsafeMutableRawPointer(callbackCtx.toOpaque()))
	}

	/**
	The maximum number of characters that can fit on the frame buffer for the specified font.

	- returns:
	The maximum number of characters for the font

	- throws:
	An error or type `PhidgetError`

	- parameters:
		- font: The specified font
	*/
	public func getMaxCharacters(font: LCDFont) throws -> Int {
		let result: PhidgetReturnCode
		var maxCharacters: Int32 = 0
		result = PhidgetLCD_getMaxCharacters(chandle, PhidgetLCD_Font(font.rawValue), &maxCharacters)
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
		return Int(maxCharacters)
	}

	/**
	Clears all pixels in the current frame buffer.

	*   Changes made to the frame buffer must be flushed to the LCD screen using `flush()`.

	- throws:
	An error or type `PhidgetError`
	*/
	public func clear() throws {
		let result: PhidgetReturnCode
		result = PhidgetLCD_clear(chandle)
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
	}

	/**
	Clears all pixels in the current frame buffer.

	*   Changes made to the frame buffer must be flushed to the LCD screen using `flush()`.

	- parameters:
		- completion: Asynchronous completion callback
	*/
	public func clear(completion: @escaping (ErrorCode) -> ()) {
		let callback = AsyncCallback(completion)
		let callbackCtx = Unmanaged.passRetained(callback)
		PhidgetLCD_clear_async(chandle, AsyncCallback.nativeAsyncCallback, UnsafeMutableRawPointer(callbackCtx.toOpaque()))
	}

	/**
	Contrast level of the text or graphic pixels.

	*   A higher contrast will make the image darker.
	*   `Contrast` is bounded by `MinContrast` and `MaxContrast`.

	- returns:
	The contrast value

	- throws:
	An error or type `PhidgetError`
	*/
	public func getContrast() throws -> Double {
		let result: PhidgetReturnCode
		var contrast: Double = 0
		result = PhidgetLCD_getContrast(chandle, &contrast)
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
		return contrast
	}

	/**
	Contrast level of the text or graphic pixels.

	*   A higher contrast will make the image darker.
	*   `Contrast` is bounded by `MinContrast` and `MaxContrast`.

	- throws:
	An error or type `PhidgetError`

	- parameters:
		- contrast: The contrast value
	*/
	public func setContrast(_ contrast: Double) throws {
		let result: PhidgetReturnCode
		result = PhidgetLCD_setContrast(chandle, contrast)
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
	}

	/**
	The minimum value that `Contrast` can be set to.

	- returns:
	The contrast value.

	- throws:
	An error or type `PhidgetError`
	*/
	public func getMinContrast() throws -> Double {
		let result: PhidgetReturnCode
		var minContrast: Double = 0
		result = PhidgetLCD_getMinContrast(chandle, &minContrast)
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
		return minContrast
	}

	/**
	The maximum value that `Contrast` can be set to.

	- returns:
	The contrast value.

	- throws:
	An error or type `PhidgetError`
	*/
	public func getMaxContrast() throws -> Double {
		let result: PhidgetReturnCode
		var maxContrast: Double = 0
		result = PhidgetLCD_getMaxContrast(chandle, &maxContrast)
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
		return maxContrast
	}

	/**
	Copies all pixels from a specified rectangular region to another.

	- throws:
	An error or type `PhidgetError`

	- parameters:
		- sourceFramebuffer: Index number of the frame buffer containing the source rectangle
		- destFramebuffer: Index number of the frame buffer containing the destination rectangle
		- sourceX1: X coordinate of upper left corner of source rectangle
		- sourceY1: Y coordinate of upper left corner of source rectangle
		- sourceX2: X coordinate of bottom right corner of source rectangle
		- sourceY2: Y coordinate of bottom right corner of source rectangle
		- destX: X coordinate of upper left corner of destination rectangle
		- destY: Y coordinate of upper left corner of destination rectangle
		- inverted: If true, copied pixels are inverted
	*/
	public func copy(sourceFramebuffer: Int, destFramebuffer: Int, sourceX1: Int, sourceY1: Int, sourceX2: Int, sourceY2: Int, destX: Int, destY: Int, inverted: Bool) throws {
		let result: PhidgetReturnCode
		result = PhidgetLCD_copy(chandle, Int32(sourceFramebuffer), Int32(destFramebuffer), Int32(sourceX1), Int32(sourceY1), Int32(sourceX2), Int32(sourceY2), Int32(destX), Int32(destY), (inverted ? 1 : 0))
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
	}

	/**
	Copies all pixels from a specified rectangular region to another.

	- parameters:
		- sourceFramebuffer: Index number of the frame buffer containing the source rectangle
		- destFramebuffer: Index number of the frame buffer containing the destination rectangle
		- sourceX1: X coordinate of upper left corner of source rectangle
		- sourceY1: Y coordinate of upper left corner of source rectangle
		- sourceX2: X coordinate of bottom right corner of source rectangle
		- sourceY2: Y coordinate of bottom right corner of source rectangle
		- destX: X coordinate of upper left corner of destination rectangle
		- destY: Y coordinate of upper left corner of destination rectangle
		- inverted: If true, copied pixels are inverted
		- completion: Asynchronous completion callback
	*/
	public func copy(sourceFramebuffer: Int, destFramebuffer: Int, sourceX1: Int, sourceY1: Int, sourceX2: Int, sourceY2: Int, destX: Int, destY: Int, inverted: Bool, completion: @escaping (ErrorCode) -> ()) {
		let callback = AsyncCallback(completion)
		let callbackCtx = Unmanaged.passRetained(callback)
		PhidgetLCD_copy_async(chandle, Int32(sourceFramebuffer), Int32(destFramebuffer), Int32(sourceX1), Int32(sourceY1), Int32(sourceX2), Int32(sourceY2), Int32(destX), Int32(destY), (inverted ? 1 : 0), AsyncCallback.nativeAsyncCallback, UnsafeMutableRawPointer(callbackCtx.toOpaque()))
	}

	/**
	When `CursorBlink` is true, the device will cause the cursor to periodically blink.

	- returns:
	The cursor blink mode

	- throws:
	An error or type `PhidgetError`
	*/
	public func getCursorBlink() throws -> Bool {
		let result: PhidgetReturnCode
		var cursorBlink: Int32 = 0
		result = PhidgetLCD_getCursorBlink(chandle, &cursorBlink)
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
		return (cursorBlink == 0 ? false : true)
	}

	/**
	When `CursorBlink` is true, the device will cause the cursor to periodically blink.

	- throws:
	An error or type `PhidgetError`

	- parameters:
		- cursorBlink: The cursor blink mode
	*/
	public func setCursorBlink(_ cursorBlink: Bool) throws {
		let result: PhidgetReturnCode
		result = PhidgetLCD_setCursorBlink(chandle, (cursorBlink ? 1 : 0))
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
	}

	/**
	When `CursorOn` is true, the device will underline to the cursor position.

	- returns:
	The cursor on value

	- throws:
	An error or type `PhidgetError`
	*/
	public func getCursorOn() throws -> Bool {
		let result: PhidgetReturnCode
		var cursorOn: Int32 = 0
		result = PhidgetLCD_getCursorOn(chandle, &cursorOn)
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
		return (cursorOn == 0 ? false : true)
	}

	/**
	When `CursorOn` is true, the device will underline to the cursor position.

	- throws:
	An error or type `PhidgetError`

	- parameters:
		- cursorOn: The cursor on value
	*/
	public func setCursorOn(_ cursorOn: Bool) throws {
		let result: PhidgetReturnCode
		result = PhidgetLCD_setCursorOn(chandle, (cursorOn ? 1 : 0))
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
	}

	/**
	Draws a straight line in the current frame buffer between two specified points

	*   Changes made to the frame buffer must be flushed to the LCD screen using `flush()`.

	- throws:
	An error or type `PhidgetError`

	- parameters:
		- x1: X coordinate of the first point
		- y1: Y coordinate of the first point
		- x2: X coordinate of the second point
		- y2: Y coordinate of the second point
	*/
	public func drawLine(x1: Int, y1: Int, x2: Int, y2: Int) throws {
		let result: PhidgetReturnCode
		result = PhidgetLCD_drawLine(chandle, Int32(x1), Int32(y1), Int32(x2), Int32(y2))
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
	}

	/**
	Draws a straight line in the current frame buffer between two specified points

	*   Changes made to the frame buffer must be flushed to the LCD screen using `flush()`.

	- parameters:
		- x1: X coordinate of the first point
		- y1: Y coordinate of the first point
		- x2: X coordinate of the second point
		- y2: Y coordinate of the second point
		- completion: Asynchronous completion callback
	*/
	public func drawLine(x1: Int, y1: Int, x2: Int, y2: Int, completion: @escaping (ErrorCode) -> ()) {
		let callback = AsyncCallback(completion)
		let callbackCtx = Unmanaged.passRetained(callback)
		PhidgetLCD_drawLine_async(chandle, Int32(x1), Int32(y1), Int32(x2), Int32(y2), AsyncCallback.nativeAsyncCallback, UnsafeMutableRawPointer(callbackCtx.toOpaque()))
	}

	/**
	Draws, erases, or inverts a single specified pixel.

	*   Changes made to the frame buffer must be flushed to the LCD screen using `flush()`.

	- throws:
	An error or type `PhidgetError`

	- parameters:
		- x: The X coordinate of the pixel
		- y: The Y coordinate of the pixel
		- pixelState: The new state of the pixel.
	*/
	public func drawPixel(x: Int, y: Int, pixelState: LCDPixelState) throws {
		let result: PhidgetReturnCode
		result = PhidgetLCD_drawPixel(chandle, Int32(x), Int32(y), PhidgetLCD_PixelState(pixelState.rawValue))
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
	}

	/**
	Draws, erases, or inverts a single specified pixel.

	*   Changes made to the frame buffer must be flushed to the LCD screen using `flush()`.

	- parameters:
		- x: The X coordinate of the pixel
		- y: The Y coordinate of the pixel
		- pixelState: The new state of the pixel.
		- completion: Asynchronous completion callback
	*/
	public func drawPixel(x: Int, y: Int, pixelState: LCDPixelState, completion: @escaping (ErrorCode) -> ()) {
		let callback = AsyncCallback(completion)
		let callbackCtx = Unmanaged.passRetained(callback)
		PhidgetLCD_drawPixel_async(chandle, Int32(x), Int32(y), PhidgetLCD_PixelState(pixelState.rawValue), AsyncCallback.nativeAsyncCallback, UnsafeMutableRawPointer(callbackCtx.toOpaque()))
	}

	/**
	Draws a rectangle in the current frame buffer using the specified points

	*   Changes made to the frame buffer must be flushed to the LCD screen using `flush()`.

	- throws:
	An error or type `PhidgetError`

	- parameters:
		- x1: The X coordinate of the top-left corner of the rectangle
		- y1: The Y coordinate of the top-left corner of the rectangle
		- x2: The X coordinate of the bottom-right corner of the rectangle
		- y2: The Y coordinate of the bottom-right corner of the rectangle
		- filled: If true, the rectangle will be solid. If false, just a single pixel outline.
		- inverted: If true, clears the region instead of drawing
	*/
	public func drawRect(x1: Int, y1: Int, x2: Int, y2: Int, filled: Bool, inverted: Bool) throws {
		let result: PhidgetReturnCode
		result = PhidgetLCD_drawRect(chandle, Int32(x1), Int32(y1), Int32(x2), Int32(y2), (filled ? 1 : 0), (inverted ? 1 : 0))
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
	}

	/**
	Draws a rectangle in the current frame buffer using the specified points

	*   Changes made to the frame buffer must be flushed to the LCD screen using `flush()`.

	- parameters:
		- x1: The X coordinate of the top-left corner of the rectangle
		- y1: The Y coordinate of the top-left corner of the rectangle
		- x2: The X coordinate of the bottom-right corner of the rectangle
		- y2: The Y coordinate of the bottom-right corner of the rectangle
		- filled: If true, the rectangle will be solid. If false, just a single pixel outline.
		- inverted: If true, clears the region instead of drawing
		- completion: Asynchronous completion callback
	*/
	public func drawRect(x1: Int, y1: Int, x2: Int, y2: Int, filled: Bool, inverted: Bool, completion: @escaping (ErrorCode) -> ()) {
		let callback = AsyncCallback(completion)
		let callbackCtx = Unmanaged.passRetained(callback)
		PhidgetLCD_drawRect_async(chandle, Int32(x1), Int32(y1), Int32(x2), Int32(y2), (filled ? 1 : 0), (inverted ? 1 : 0), AsyncCallback.nativeAsyncCallback, UnsafeMutableRawPointer(callbackCtx.toOpaque()))
	}

	/**
	Flushes the buffered LCD contents to the LCD screen.

	- throws:
	An error or type `PhidgetError`
	*/
	public func flush() throws {
		let result: PhidgetReturnCode
		result = PhidgetLCD_flush(chandle)
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
	}

	/**
	Flushes the buffered LCD contents to the LCD screen.

	- parameters:
		- completion: Asynchronous completion callback
	*/
	public func flush(completion: @escaping (ErrorCode) -> ()) {
		let callback = AsyncCallback(completion)
		let callbackCtx = Unmanaged.passRetained(callback)
		PhidgetLCD_flush_async(chandle, AsyncCallback.nativeAsyncCallback, UnsafeMutableRawPointer(callbackCtx.toOpaque()))
	}

	/**
	Gets the size of the specified font.

	- returns:
		- width: The width of the font
		- height: The height of the font

	- throws:
	An error or type `PhidgetError`

	- parameters:
		- font: The specified font
	*/
	public func getFontSize(font: LCDFont) throws -> (width: Int, height: Int) {
		let result: PhidgetReturnCode
		var width: Int32 = 0
		var height: Int32 = 0
		result = PhidgetLCD_getFontSize(chandle, PhidgetLCD_Font(font.rawValue), &width, &height)
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
		return (width: Int(width), height: Int(height))
	}

	/**
	Sets the size of the specified font.

	- throws:
	An error or type `PhidgetError`

	- parameters:
		- font: The specified font
		- width: The width of the font
		- height: The height of the font
	*/
	public func setFontSize(font: LCDFont, width: Int, height: Int) throws {
		let result: PhidgetReturnCode
		result = PhidgetLCD_setFontSize(chandle, PhidgetLCD_Font(font.rawValue), Int32(width), Int32(height))
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
	}

	/**
	The frame buffer that is currently being used.

	*   Commands sent to the device are performed on this buffer.

	- returns:
	The current frame buffer

	- throws:
	An error or type `PhidgetError`
	*/
	public func getFrameBuffer() throws -> Int {
		let result: PhidgetReturnCode
		var frameBuffer: Int32 = 0
		result = PhidgetLCD_getFrameBuffer(chandle, &frameBuffer)
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
		return Int(frameBuffer)
	}

	/**
	The frame buffer that is currently being used.

	*   Commands sent to the device are performed on this buffer.

	- throws:
	An error or type `PhidgetError`

	- parameters:
		- frameBuffer: The current frame buffer
	*/
	public func setFrameBuffer(_ frameBuffer: Int) throws {
		let result: PhidgetReturnCode
		result = PhidgetLCD_setFrameBuffer(chandle, Int32(frameBuffer))
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
	}

	/**
	The frame buffer that is currently being used.

	*   Commands sent to the device are performed on this buffer.

	- parameters:
		- frameBuffer: The current frame buffer
		- completion: Asynchronous completion callback
	*/
	public func setFrameBuffer(_ frameBuffer: Int, completion: @escaping (ErrorCode) -> ()) {
		let callback = AsyncCallback(completion)
		let callbackCtx = Unmanaged.passRetained(callback)
		PhidgetLCD_setFrameBuffer_async(chandle, Int32(frameBuffer), AsyncCallback.nativeAsyncCallback, UnsafeMutableRawPointer(callbackCtx.toOpaque()))
	}

	/**
	The height of the LCD screen attached to the channel.

	- returns:
	The height value

	- throws:
	An error or type `PhidgetError`
	*/
	public func getHeight() throws -> Int {
		let result: PhidgetReturnCode
		var height: Int32 = 0
		result = PhidgetLCD_getHeight(chandle, &height)
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
		return Int(height)
	}

	/**
	Initializes the Text LCD display

	- throws:
	An error or type `PhidgetError`
	*/
	public func initialize() throws {
		let result: PhidgetReturnCode
		result = PhidgetLCD_initialize(chandle)
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
	}

	/**
	Writes the specified frame buffer to flash memory

	*   Use sparingly. The flash memory is only designed to be written to 10,000 times before it may become unusable. This method can only be called one time each time the channel is opened.

	- throws:
	An error or type `PhidgetError`

	- parameters:
		- frameBuffer: The frame buffer to be saved
	*/
	public func saveFrameBuffer(frameBuffer: Int) throws {
		let result: PhidgetReturnCode
		result = PhidgetLCD_saveFrameBuffer(chandle, Int32(frameBuffer))
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
	}

	/**
	Writes the specified frame buffer to flash memory

	*   Use sparingly. The flash memory is only designed to be written to 10,000 times before it may become unusable. This method can only be called one time each time the channel is opened.

	- parameters:
		- frameBuffer: The frame buffer to be saved
		- completion: Asynchronous completion callback
	*/
	public func saveFrameBuffer(frameBuffer: Int, completion: @escaping (ErrorCode) -> ()) {
		let callback = AsyncCallback(completion)
		let callbackCtx = Unmanaged.passRetained(callback)
		PhidgetLCD_saveFrameBuffer_async(chandle, Int32(frameBuffer), AsyncCallback.nativeAsyncCallback, UnsafeMutableRawPointer(callbackCtx.toOpaque()))
	}

	/**
	The size of the LCD screen attached to the channel.

	- returns:
	The screen size

	- throws:
	An error or type `PhidgetError`
	*/
	public func getScreenSize() throws -> LCDScreenSize {
		let result: PhidgetReturnCode
		var screenSize: PhidgetLCD_ScreenSize = SCREEN_SIZE_NONE
		result = PhidgetLCD_getScreenSize(chandle, &screenSize)
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
		return LCDScreenSize(rawValue: screenSize.rawValue)!
	}

	/**
	The size of the LCD screen attached to the channel.

	- throws:
	An error or type `PhidgetError`

	- parameters:
		- screenSize: The screen size
	*/
	public func setScreenSize(_ screenSize: LCDScreenSize) throws {
		let result: PhidgetReturnCode
		result = PhidgetLCD_setScreenSize(chandle, PhidgetLCD_ScreenSize(screenSize.rawValue))
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
	}

	/**
	The on/off state of `Sleeping`. Putting the device to sleep turns off the display and backlight in order to save power.

	*   The device will still take commands while asleep, and will wake up if the screen is flushed, or if the contrast or backlight are changed.
	*   When the device wakes up, it will return to its last known state, taking into account any changes that happened while asleep.

	- returns:
	The sleep status

	- throws:
	An error or type `PhidgetError`
	*/
	public func getSleeping() throws -> Bool {
		let result: PhidgetReturnCode
		var sleeping: Int32 = 0
		result = PhidgetLCD_getSleeping(chandle, &sleeping)
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
		return (sleeping == 0 ? false : true)
	}

	/**
	The on/off state of `Sleeping`. Putting the device to sleep turns off the display and backlight in order to save power.

	*   The device will still take commands while asleep, and will wake up if the screen is flushed, or if the contrast or backlight are changed.
	*   When the device wakes up, it will return to its last known state, taking into account any changes that happened while asleep.

	- throws:
	An error or type `PhidgetError`

	- parameters:
		- sleeping: The sleep status
	*/
	public func setSleeping(_ sleeping: Bool) throws {
		let result: PhidgetReturnCode
		result = PhidgetLCD_setSleeping(chandle, (sleeping ? 1 : 0))
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
	}

	/**
	The width of the LCD screen attached to the channel.

	- returns:
	The width value

	- throws:
	An error or type `PhidgetError`
	*/
	public func getWidth() throws -> Int {
		let result: PhidgetReturnCode
		var width: Int32 = 0
		result = PhidgetLCD_getWidth(chandle, &width)
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
		return Int(width)
	}

	/**
	Draws a bitmap to the current frame buffer at the given location.

	*   Each byte in the array represents one pixel in row-major order.
	*   Changes made to the frame buffer must be flushed to the LCD screen using `flush()`.

	- throws:
	An error or type `PhidgetError`

	- parameters:
		- xPosition: The X coordinate of the bitmap
		- yPosition: The Y coordinate of the bitmap
		- xSize: The length of each row in the bitmap
		- ySize: The number of rows in the bitmap
		- bitmap: The bitmap to be drawn
	*/
	public func writeBitmap(xPosition: Int, yPosition: Int, xSize: Int, ySize: Int, bitmap: [UInt8]) throws {
		let result: PhidgetReturnCode
		result = PhidgetLCD_writeBitmap(chandle, Int32(xPosition), Int32(yPosition), Int32(xSize), Int32(ySize), bitmap)
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
	}

	/**
	Draws a bitmap to the current frame buffer at the given location.

	*   Each byte in the array represents one pixel in row-major order.
	*   Changes made to the frame buffer must be flushed to the LCD screen using `flush()`.

	- parameters:
		- xPosition: The X coordinate of the bitmap
		- yPosition: The Y coordinate of the bitmap
		- xSize: The length of each row in the bitmap
		- ySize: The number of rows in the bitmap
		- bitmap: The bitmap to be drawn
		- completion: Asynchronous completion callback
	*/
	public func writeBitmap(xPosition: Int, yPosition: Int, xSize: Int, ySize: Int, bitmap: [UInt8], completion: @escaping (ErrorCode) -> ()) {
		let callback = AsyncCallback(completion)
		let callbackCtx = Unmanaged.passRetained(callback)
		PhidgetLCD_writeBitmap_async(chandle, Int32(xPosition), Int32(yPosition), Int32(xSize), Int32(ySize), bitmap, AsyncCallback.nativeAsyncCallback, UnsafeMutableRawPointer(callbackCtx.toOpaque()))
	}

	/**
	Writes text to the current frame buffer at the specified location

	*   Changes made to the frame buffer must be flushed to the LCD screen using `flush()`.

	- throws:
	An error or type `PhidgetError`

	- parameters:
		- font: The font of the text
		- xPosition: The X position of the start of the text string
		- yPosition: The Y position of the start of the text string
		- text: The text to be written
	*/
	public func writeText(font: LCDFont, xPosition: Int, yPosition: Int, text: String) throws {
		let result: PhidgetReturnCode
		result = PhidgetLCD_writeText(chandle, PhidgetLCD_Font(font.rawValue), Int32(xPosition), Int32(yPosition), text)
		if result != EPHIDGET_OK {
			throw (PhidgetError(code: result))
		}
	}

	/**
	Writes text to the current frame buffer at the specified location

	*   Changes made to the frame buffer must be flushed to the LCD screen using `flush()`.

	- parameters:
		- font: The font of the text
		- xPosition: The X position of the start of the text string
		- yPosition: The Y position of the start of the text string
		- text: The text to be written
		- completion: Asynchronous completion callback
	*/
	public func writeText(font: LCDFont, xPosition: Int, yPosition: Int, text: String, completion: @escaping (ErrorCode) -> ()) {
		let callback = AsyncCallback(completion)
		let callbackCtx = Unmanaged.passRetained(callback)
		PhidgetLCD_writeText_async(chandle, PhidgetLCD_Font(font.rawValue), Int32(xPosition), Int32(yPosition), text, AsyncCallback.nativeAsyncCallback, UnsafeMutableRawPointer(callbackCtx.toOpaque()))
	}

}
