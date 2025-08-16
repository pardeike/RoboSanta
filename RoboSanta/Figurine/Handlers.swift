struct Handlers {
    func attach_handler(sender: Phidget) {
        print("> attached")
        do {
            let attachedDevice = sender as! RCServo
            let deviceID = try attachedDevice.getDeviceID()
            print("engaged = \(try attachedDevice.getEngaged())")
            print("minPulseWidth = \(try attachedDevice.getMinPulseWidth())")
            print("maxPulseWidth = \(try attachedDevice.getMaxPulseWidth())")
            
            print("device id = \(deviceID)")
            if(deviceID == DeviceID.PN_1061 || deviceID == DeviceID.PN_1066){
                print("minDataInterval = \(try attachedDevice.getMinDataInterval())")
                print("maxDataInterval = \(try attachedDevice.getMaxDataInterval())")
                print("dataInterval = \(try attachedDevice.getDataInterval())")
            }
            
            print("channel = \(try sender.getChannel())")
            print("deviceVersion = \(try sender.getDeviceVersion())")
            print("deviceName = \(try sender.getDeviceName())")
        } catch let err as PhidgetError {
            outputError(errorDescription: err.description, errorCode: err.errorCode.rawValue)
        } catch {
            print (error)
        }
    }
    
    func detach_handler(sender: Phidget) {
        print("> detached")
    }
    
    func error_handler(sender: Phidget, data: (code: ErrorEventCode, description: String)){
        outputError(errorDescription: data.description, errorCode: data.code.rawValue)
    }
    
    func positionchange_handler(sender: RCServo, position: Double) {
        print("> position changed: \(position)")
    }
    
    func velocitychange_handler(sender: RCServo, velocity: Double) {
        print("> velocity changed: \(velocity)")
    }
    
    func targetreached_handler(sender: RCServo, position: Double) {
        print("> target reached: \(position)")
    }
}
