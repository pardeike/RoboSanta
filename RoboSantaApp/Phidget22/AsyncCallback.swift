//
//  AsyncCallback.swift
//  
//
//  Created by Patrick McNeil on 2018-01-18.
//

import Foundation
//import Phidget22

internal class AsyncCallback {
	
	internal var completion: (ErrorCode) -> ()
	internal init(_ completion: @escaping (ErrorCode) -> ()) {
		self.completion = completion
	}
	
	static internal let nativeAsyncCallback: Phidget_AsyncCallback = { ch, ctx, res in
		let callbackCtx = Unmanaged<AsyncCallback>.fromOpaque(ctx!)
		let a = callbackCtx.takeUnretainedValue()
		a.completion(ErrorCode(rawValue: res.rawValue)!)
		callbackCtx.release()
	}
}
