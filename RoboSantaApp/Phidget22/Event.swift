//
//  Event.swift
//  Phidget22Swift
//
//  Created by Patrick McNeil on 2018-01-16.
//  Copyright © 2018 Phidgets Inc. All rights reserved.
//
//	Source: http://blog.scottlogic.com/2015/02/05/swift-events.html

import Foundation

internal enum EventType {
	case TargetAction
	case Action
}

public class Event<P:AnyObject,T> {
	
	public typealias EventHandler = (P,T) -> ()
	
	internal var eventHandlers = [Invocable]()
	
	internal func raise(_ sender: P, _ data: T) {
		for handler in self.eventHandlers {
			handler.invoke(sender: sender, data: data)
		}
	}
	
	/**
	Adds an event handler.
	
	- returns:
	The handler result, which can be used to remove the handler
	
	- parameters:
		- target: Target object on which to perform events
		- handler: Handler which is a member of the target
	*/
	public func addHandler<U: AnyObject>(target: U, handler: @escaping (U) -> EventHandler) -> Handler {
		let wrapper = EventHandlerWrapper(target: target, handler: handler, event: self)
		eventHandlers.append(wrapper)
		return wrapper
	}
	
	/**
	Adds an event handler.
	
	- returns:
	The handler result, which can be used to remove the handler
	
	- parameters:
		- handler: function or closure
	*/
	public func addHandler(_ handler: @escaping EventHandler) -> Handler {
		let wrapper = EventHandlerWrapper<AnyObject, P, T>(handler: handler, event: self)
		eventHandlers.append(wrapper)
		return wrapper
	}
	
	/**
	Removes an event handler.
	
	- parameters:
		- handler: The handler to remove
	*/
	public func removeHandler(_ handler: Handler) {
		eventHandlers = eventHandlers.filter { $0 !== (handler as? Invocable) }
	}
	
	/**
	Removes all event handlers.
	*/
	public func removeAllHandlers() {
		eventHandlers = [Invocable]()
	}
}

internal protocol Invocable: AnyObject {
	func invoke(sender: AnyObject, data: Any)
}

internal class EventHandlerWrapper<T: AnyObject, P:AnyObject, U> : Invocable, Handler {
	weak var target: T?
	let handler: ((T) -> (P, U) -> ())?
	let handler2: ((P, U) -> ())?
	let event: Event<P,U>
	let type: EventType
	
	init(target: T?, handler: @escaping (T) -> (P,U) -> (), event: Event<P,U>) {
		self.target = target
		self.handler = handler
		self.handler2 = nil
		self.event = event
		type = .TargetAction
	}
	
	init(handler: @escaping (P,U) -> (), event: Event<P,U>) {
		self.handler2 = handler
		self.handler = nil
		self.event = event;
		type = .Action
	}
	
	func invoke(sender: AnyObject, data: Any) -> () {
		if type == .TargetAction {
			if let t = target {
				handler!(t)(sender as! P, data as! U)
			}
		} else {
			handler2!(sender as! P, data as! U)
		}
	}
	
	func remove() {
		event.eventHandlers =
			event.eventHandlers.filter { $0 !== self }
	}
}
public class StaticEvent<T> {
	
	public typealias StaticEventHandler = (T) -> ()

	public init(cinit: @escaping ()->()) {
		cinit()
	}
	
	internal var eventHandlers = [StaticInvocable]()
	
	internal func raise(_ data: T) {
		for handler in self.eventHandlers {
			handler.invoke(data: data)
		}
	}
	
	/**
	Adds an event handler.
	
	- returns:
	The handler result, which can be used to remove the handler
	
	- parameters:
	- target: Target object on which to perform events
	- handler: Handler which is a member of the target
	*/
	public func addHandler<U: AnyObject>(target: U, handler: @escaping (U) -> StaticEventHandler) -> Handler {
		let wrapper = StaticEventHandlerWrapper(target: target, handler: handler, event: self)
		eventHandlers.append(wrapper)
		return wrapper
	}
	
	/**
	Adds an event handler.
	
	- returns:
	The handler result, which can be used to remove the handler
	
	- parameters:
	- handler: function or closure
	*/
	public func addHandler(_ handler: @escaping StaticEventHandler) -> Handler {
		let wrapper = StaticEventHandlerWrapper<AnyObject, T>(handler: handler, event: self)
		eventHandlers.append(wrapper)
		return wrapper
	}
	
	/**
	Removes an event handler.
	
	- parameters:
	- handler: The handler to remove
	*/
	public func removeHandler(_ handler: Handler) {
		eventHandlers = eventHandlers.filter { $0 !== (handler as? StaticInvocable) }
	}
	
	/**
	Removes all event handlers.
	*/
	public func removeAllHandlers() {
		eventHandlers = [StaticInvocable]()
	}
}

internal protocol StaticInvocable: AnyObject {
	func invoke(data: Any)
}

internal class StaticEventHandlerWrapper<T: AnyObject, U> : StaticInvocable, Handler {
	weak var target: T?
	let handler: ((T) -> (U) -> ())?
	let handler2: ((U) -> ())?
	let event: StaticEvent<U>
	let type: EventType
	
	init(target: T?, handler: @escaping (T) -> (U) -> (), event: StaticEvent<U>) {
		self.target = target
		self.handler = handler
		self.handler2 = nil
		self.event = event
		type = .TargetAction
	}
	
	init(handler: @escaping (U) -> (), event: StaticEvent<U>) {
		self.handler2 = handler
		self.handler = nil
		self.event = event;
		type = .Action
	}
	
	func invoke(data: Any) -> () {
		if type == .TargetAction {
			if let t = target {
				handler!(t)(data as! U)
			}
		} else {
			handler2!(data as! U)
		}
	}
	
	func remove() {
		event.eventHandlers =
			event.eventHandlers.filter { $0 !== self }
	}
}
public class SimpleEvent<T:AnyObject> {
	
	public typealias SimpleEventHandler = (T) -> ()
	
	internal var eventHandlers = [SimpleInvocable]()
	
	internal func raise(_ sender: T) {
		for handler in self.eventHandlers {
			handler.invoke(sender: sender)
		}
	}
	
	/**
	Adds an event handler.
	
	- returns:
	The handler result, which can be used to remove the handler
	
	- parameters:
	- target: Target object on which to perform events
	- handler: Handler which is a member of the target
	*/
	public func addHandler<U: AnyObject>(target: U, handler: @escaping (U) -> SimpleEventHandler) -> Handler {
		let wrapper = SimpleEventHandlerWrapper(target: target, handler: handler, event: self)
		eventHandlers.append(wrapper)
		return wrapper
	}
	
	/**
	Adds an event handler.
	
	- returns:
	The handler result, which can be used to remove the handler
	
	- parameters:
	- handler: function or closure
	*/
	public func addHandler(_ handler: @escaping SimpleEventHandler) -> Handler {
		let wrapper = SimpleEventHandlerWrapper<AnyObject, T>(handler: handler, event: self)
		eventHandlers.append(wrapper)
		return wrapper
	}
	
	/**
	Removes an event handler.
	
	- parameters:
	- handler: The handler to remove
	*/
	public func removeHandler(_ handler: Handler) {
		eventHandlers = eventHandlers.filter { $0 !== (handler as? SimpleInvocable) }
	}
	
	/**
	Removes all event handlers.
	*/
	public func removeAllHandlers() {
		eventHandlers = [SimpleInvocable]()
	}
}

internal protocol SimpleInvocable: AnyObject {
	func invoke(sender: AnyObject)
}

internal class SimpleEventHandlerWrapper<T: AnyObject, U: AnyObject> : SimpleInvocable, Handler {
	weak var target: T?
	let handler: ((T) -> (U) -> ())?
	let handler2: ((U) -> ())?
	let event: SimpleEvent<U>
	let type: EventType
	
	init(target: T?, handler: @escaping (T) -> (U) -> (), event: SimpleEvent<U>) {
		self.target = target
		self.handler = handler
		self.handler2 = nil
		self.event = event
		type = .TargetAction
	}
	
	init(handler: @escaping (U) -> (), event: SimpleEvent<U>) {
		self.handler2 = handler
		self.handler = nil
		self.event = event;
		type = .Action
	}
	
	func invoke(sender: AnyObject) -> () {
		if type == .TargetAction {
			if let t = target {
				handler!(t)(sender as! U)
			}
		} else {
			handler2!(sender as! U)
		}
	}
	
	func remove() {
		event.eventHandlers =
			event.eventHandlers.filter { $0 !== self }
	}
}

public protocol Handler {
	
	/**
	Removes this event handler.
	*/
	func remove()
}
