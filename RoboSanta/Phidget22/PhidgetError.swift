//
//  PhidgetError.swift
//  
//
//  Created by Patrick McNeil on 2018-01-10.
//

import Foundation
//import Phidget22

public struct PhidgetError: Error {
	public let errorCode: ErrorCode
	public let description: String
	public let detail: String
	
	public init(code: PhidgetReturnCode) {
		var errorDescriptionString: UnsafePointer<Int8>? = nil
		var errorDetailStringLen: Int = 0
		var lastCode: PhidgetReturnCode = EPHIDGET_OK
		
		errorCode = ErrorCode(rawValue: code.rawValue)!
		
		var ret = Phidget_getLastError(&lastCode, &errorDescriptionString, nil, &errorDetailStringLen)
		if (ret == EPHIDGET_OK && lastCode == code) {
			let errorDetailString: UnsafeMutablePointer<CChar> = UnsafeMutablePointer<CChar>.allocate(capacity: errorDetailStringLen)
			ret = Phidget_getLastError(&lastCode, &errorDescriptionString, errorDetailString, &errorDetailStringLen)
			if (ret == EPHIDGET_OK) {
				description = String(cString: errorDescriptionString!)
				detail = String(cString: errorDetailString)
				errorDetailString.deallocate()
				return
			}
			errorDetailString.deallocate()
		}
		
		ret = Phidget_getErrorDescription(code, &errorDescriptionString)
		if (ret == EPHIDGET_OK) {
			description = String(cString: errorDescriptionString!)
			detail = ""
		} else {
			description = ""
			detail = ""
		}
	}
}

