struct Functions {
    let ch: RCServo
    
    func setTargetPosition(_ val: Double) {
        do {
            try ch.setTargetPosition(val)
        } catch let err as PhidgetError {
            outputError(errorDescription: err.description, errorCode: err.errorCode.rawValue)
        } catch {
            print (error)
        }
    }
    
    func engageMotor(_ engaged: Bool) {
        do {
            try ch.setEngaged(engaged)
        } catch let err as PhidgetError {
            outputError(errorDescription: err.description, errorCode: err.errorCode.rawValue)
        } catch {
            print (error)
        }
    }
    
    func setAcceleration(_ val: Double) {
        do {
            try ch.setAcceleration(val)
        } catch let err as PhidgetError {
            outputError(errorDescription: err.description, errorCode: err.errorCode.rawValue)
        } catch {
            print (error)
        }
    }
    
    func setVelocityLimit(_ val: Double) {
        do {
            try ch.setVelocityLimit(val)
        } catch let err as PhidgetError {
            outputError(errorDescription: err.description, errorCode: err.errorCode.rawValue)
        } catch {
            print (error)
        }
    }
    
    func setSpeedRampingState(_ val: Bool) {
        do {
            try ch.setSpeedRampingState(val)
        } catch let err as PhidgetError {
            outputError(errorDescription: err.description, errorCode: err.errorCode.rawValue)
        } catch {
            print (error)
        }
    }
    
    func setVoltage(_ voltage: RCServoVoltage) {
        do {
            try ch.setVoltage(voltage)
        } catch let err as PhidgetError {
            outputError(errorDescription: err.description, errorCode: err.errorCode.rawValue)
        } catch {
            print (error)
        }
    }
}
