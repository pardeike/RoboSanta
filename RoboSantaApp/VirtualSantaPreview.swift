import SwiftUI
import SceneKit
import AppKit
import Combine

/// Builds and updates a lightweight 3D Santa model for the virtual rig.
@MainActor
final class SantaPreviewRenderer {
    
    let scene: SCNScene
    let cameraNode: SCNNode
    
    private let focusNode = SCNNode()
    private let bodyPivot = SCNNode()
    private let headPivot = SCNNode()
    private let leftArmPivot = SCNNode()
    private let rightArmPivot = SCNNode()
    private let personNode = SCNNode()
    private let personHeadNode = SCNNode()
    private let personBodyNode = SCNNode()
    private let personHeadRadius: CGFloat = 0.3
    private let personHeadSegments: Int = 12
    private let personDistance: Float = 2
    private let personWalkHalfWidth: Float = 0.8 * 3
    private let personFloorHeight: CGFloat = 0.002
    private var personHeadCenterHeight: Float = 1.0
    private lazy var personMaterial: SCNMaterial = {
        let mat = material(color: .green.withAlphaComponent(0.8))
        mat.fillMode = .fill
        return mat
    }()
    private var headCenterHeight: Float = 1.0
    private var baseRadius: Double = 1.0
    private var baseAzimuth: Double = 0.0
    private var baseElevation: Double = 0.0
    private let armAngleRange: ClosedRange<Double> = -120...70 // degrees from relaxed to raised
    
    init() {
        scene = SCNScene()
        cameraNode = SCNNode()
        setupScene()
        apply(pose: StateMachine.FigurinePose())
        captureCameraDefaults()
    }
    
    func apply(pose: StateMachine.FigurinePose) {
        bodyPivot.eulerAngles.y = CGFloat(deg2rad(pose.bodyAngle))
        headPivot.eulerAngles.y = CGFloat(deg2rad(pose.headAngle))
        leftArmPivot.eulerAngles.x = CGFloat(armAngle(for: pose.leftHand))
        rightArmPivot.eulerAngles.x = CGFloat(armAngle(for: pose.rightHand))
    }
    
    func applyPerson(relativeOffset: Double?) {
        guard let offset = relativeOffset else {
            personNode.isHidden = true
            return
        }
        personNode.isHidden = false
        let clamped = offset.clamped(to: -1...1)
        let x = Float(clamped) * personWalkHalfWidth
        let y: Float = personHeadCenterHeight
        let z: Float = personDistance
        personNode.position = SCNVector3(x, y, z)
    }
    
    func updateCamera(azimuthDegrees: Double, zoomScale: Double) {
        let radius = baseRadius * zoomScale
        let azimuth = deg2rad(azimuthDegrees)
        let xzPlane = radius * cos(baseElevation)
        let x = xzPlane * cos(azimuth)
        let z = xzPlane * sin(azimuth)
        let y = radius * sin(baseElevation)
        cameraNode.position = SCNVector3(
            focusNode.position.x + CGFloat(x),
            focusNode.position.y + CGFloat(y),
            focusNode.position.z + CGFloat(z)
        )
    }
    
    var defaultAzimuthDegrees: Double {
        rad2deg(Double(baseAzimuth))
    }
    
    // MARK: - Scene setup
    
    private func setupScene() {
        scene.background.contents = NSColor(calibratedWhite: 0.08, alpha: 1.0)
        buildLights()
        buildCamera()
        buildGround()
        buildFigurine()
    }
    
    private func buildLights() {
        let ambient = SCNLight()
        ambient.type = .ambient
        ambient.intensity = 250
        ambient.color = NSColor(calibratedWhite: 0.7, alpha: 1.0)
        let ambientNode = SCNNode()
        ambientNode.light = ambient
        scene.rootNode.addChildNode(ambientNode)
        
        let key = SCNLight()
        key.type = .directional
        key.intensity = 1200
        key.castsShadow = true
        key.shadowRadius = 8
        key.shadowColor = NSColor.black.withAlphaComponent(0.3)
        let keyNode = SCNNode()
        keyNode.light = key
        keyNode.eulerAngles = SCNVector3(-.pi / 3.2, .pi / 3.6, 0)
        scene.rootNode.addChildNode(keyNode)
        
        let fill = SCNLight()
        fill.type = .directional
        fill.intensity = 500
        let fillNode = SCNNode()
        fillNode.light = fill
        fillNode.eulerAngles = SCNVector3(.pi / 4.5, -.pi / 4, 0)
        scene.rootNode.addChildNode(fillNode)
    }
    
    private func buildCamera() {
        focusNode.position = SCNVector3(0, 0.9, 0)
        scene.rootNode.addChildNode(focusNode)
        
        let camera = SCNCamera()
        camera.zNear = 0.05
        camera.zFar = 50
        cameraNode.camera = camera
        cameraNode.position = SCNVector3(2.6, 1.9, 2.6)
        let constraint = SCNLookAtConstraint(target: focusNode)
        constraint.isGimbalLockEnabled = true
        cameraNode.constraints = [constraint]
        scene.rootNode.addChildNode(cameraNode)
    }
    
    private func buildGround() {
        let floor = SCNFloor()
        floor.reflectionFalloffStart = 0
        floor.reflectionFalloffEnd = 0
        floor.reflectivity = 0.05
        let material = SCNMaterial()
        material.diffuse.contents = NSColor(calibratedWhite: 0.12, alpha: 1.0)
        material.roughness.contents = 0.6
        floor.firstMaterial = material
        
        let floorNode = SCNNode(geometry: floor)
        floorNode.position = SCNVector3(0, 0, 0)
        scene.rootNode.addChildNode(floorNode)
    }
    
    private func buildFigurine() {
        let baseRadius: CGFloat = 0.45
        let baseHeight: CGFloat = 0.25
        let bodyRadius: CGFloat = 0.45
        let bodyHeight: CGFloat = 1.1
        let headRadius: CGFloat = 0.32
        let armRadius: CGFloat = 0.14
        let armLength: CGFloat = 0.75
        let cameraStubRadius: CGFloat = 0.06
        let cameraStubLength: CGFloat = 0.16
        
        // Base cylinder
        let base = SCNCylinder(radius: baseRadius, height: baseHeight)
        base.firstMaterial = material(color: NSColor(calibratedRed: 0.45, green: 0.06, blue: 0.09, alpha: 1))
        let baseNode = SCNNode(geometry: base)
        baseNode.position = SCNVector3(0, baseHeight / 2, 0)
        scene.rootNode.addChildNode(baseNode)
        
        // Body pivot placed at the top of the base
        // Rotating this matches the body servo.
        bodyPivot.position = SCNVector3(0, baseHeight, 0)
        scene.rootNode.addChildNode(bodyPivot)
        
        let body = SCNCylinder(radius: bodyRadius, height: bodyHeight)
        body.firstMaterial = material(color: NSColor(calibratedRed: 0.82, green: 0.09, blue: 0.12, alpha: 1))
        let bodyNode = SCNNode(geometry: body)
        bodyNode.position = SCNVector3(0, bodyHeight / 2, 0)
        bodyPivot.addChildNode(bodyNode)
        
        // Head pivot sits on top of the body and
        // rotates independently of the body yaw.
        headPivot.position = SCNVector3(0, bodyHeight, 0)
        bodyPivot.addChildNode(headPivot)
        
        let head = SCNSphere(radius: headRadius)
        head.firstMaterial = material(color: NSColor(calibratedRed: 0.98, green: 0.92, blue: 0.86, alpha: 1))
        let headNode = SCNNode(geometry: head)
        headNode.position = SCNVector3(0, headRadius, 0)
        headPivot.addChildNode(headNode)
        headCenterHeight = Float(bodyHeight + headRadius)
        personHeadCenterHeight = headCenterHeight + Float(personHeadRadius * 2)
        
        // Camera stub on the upper front of the head.
        let cameraStub = SCNCylinder(radius: cameraStubRadius, height: cameraStubLength)
        cameraStub.firstMaterial = material(color: NSColor(calibratedWhite: 0.15, alpha: 1.0))
        let stubNode = SCNNode(geometry: cameraStub)
        stubNode.position = SCNVector3(0, headRadius * 0.4, headRadius + cameraStubLength / 2)
        stubNode.eulerAngles.x = .pi / 2
        headNode.addChildNode(stubNode)
    
        let eyeRadius: CGFloat = 0.055
        let eyeDepth: CGFloat = eyeRadius * 0.6
        let eyeOffsetY: CGFloat = 0
        let eyeOffsetZ: CGFloat = headRadius - eyeDepth
        let eyeOffsetX: CGFloat = 0.12
        let eyeMaterial = material(color: .systemBlue)
        let leftEye = SCNSphere(radius: eyeRadius)
        leftEye.firstMaterial = eyeMaterial
        let leftEyeNode = SCNNode(geometry: leftEye)
        leftEyeNode.position = SCNVector3(-eyeOffsetX, eyeOffsetY, eyeOffsetZ)
        headNode.addChildNode(leftEyeNode)
        
        let rightEye = SCNSphere(radius: eyeRadius)
        rightEye.firstMaterial = eyeMaterial
        let rightEyeNode = SCNNode(geometry: rightEye)
        rightEyeNode.position = SCNVector3(eyeOffsetX, eyeOffsetY, eyeOffsetZ)
        headNode.addChildNode(rightEyeNode)
        
        // Arms mounted to the body sides with their own pivots.
        let shoulderHeight = bodyHeight * 0.82
        let shoulderOffset = bodyRadius + armRadius * 1.2
        let armGeometry = SCNCylinder(radius: armRadius, height: armLength)
        armGeometry.firstMaterial = material(color: NSColor(calibratedRed: 0.82, green: 0.09, blue: 0.12, alpha: 1))
        
        leftArmPivot.position = SCNVector3(-shoulderOffset, shoulderHeight, 0)
        bodyPivot.addChildNode(leftArmPivot)
        let leftArm = SCNNode(geometry: armGeometry)
        leftArm.position = SCNVector3(0, -armLength / 2, 0)
        leftArmPivot.addChildNode(leftArm)
        
        rightArmPivot.position = SCNVector3(shoulderOffset, shoulderHeight, 0)
        bodyPivot.addChildNode(rightArmPivot)
        let rightArm = SCNNode(geometry: armGeometry)
        rightArm.position = SCNVector3(0, -armLength / 2, 0)
        rightArmPivot.addChildNode(rightArm)
        
        // Virtual person marker in front of Santa.
        let personHead = SCNSphere(radius: personHeadRadius)
        personHead.segmentCount = personHeadSegments
        personHead.firstMaterial = personMaterial
        personHeadNode.geometry = personHead
        personHeadNode.position = SCNVector3Zero
        
        let availableHeight = CGFloat(personHeadCenterHeight) - personHeadRadius - personFloorHeight
        let personBodyHeight = max(0.001, availableHeight)
        let bodySize = personHeadRadius * 2.2
        let personBody = SCNBox(width: bodySize, height: personBodyHeight, length: bodySize, chamferRadius: 0)
        personBody.firstMaterial = personMaterial
        personBodyNode.geometry = personBody
        personBodyNode.position = SCNVector3(
            0,
            -Float(personHeadRadius + personBodyHeight / 2),
            0
        )
        personBodyNode.castsShadow = false
        
        personNode.addChildNode(personHeadNode)
        personNode.addChildNode(personBodyNode)
        personNode.position = SCNVector3(0, personHeadCenterHeight, personDistance)
        personNode.isHidden = true
        scene.rootNode.addChildNode(personNode)
        buildPersonArea()
    }
    
    // MARK: - Helpers
    
    private func buildPersonArea() {
        let walkSpan = CGFloat(personWalkHalfWidth * 2)
        let floorDepth = personHeadRadius * 4
        let floorWidth = walkSpan + floorDepth
        let floorLength = floorDepth
        
        let box = SCNBox(width: floorWidth, height: personFloorHeight, length: floorLength, chamferRadius: 0)
        let material = SCNMaterial()
        material.diffuse.contents = NSColor(calibratedWhite: 0.78, alpha: 1.0)
        material.roughness.contents = 0.8
        material.metalness.contents = 0.0
        box.firstMaterial = material
        
        let node = SCNNode(geometry: box)
        node.position = SCNVector3(0, Float(personFloorHeight / 2), personDistance)
        node.castsShadow = false
        scene.rootNode.addChildNode(node)
    }
    
    private func armAngle(for handValue: Double) -> Double {
        let clamped = handValue.clamped(to: 0...1)
        let degrees = armAngleRange.lowerBound + clamped * (armAngleRange.upperBound - armAngleRange.lowerBound)
        return deg2rad(degrees)
    }
    
    private func material(color: NSColor) -> SCNMaterial {
        let mat = SCNMaterial()
        mat.diffuse.contents = color
        mat.roughness.contents = 0.35
        mat.metalness.contents = 0.05
        return mat
    }
    
    private func deg2rad(_ degrees: Double) -> Double {
        degrees * .pi / 180
    }
    
    private func rad2deg(_ radians: Double) -> Double {
        radians * 180 / .pi
    }
    
    private func captureCameraDefaults() {
        let offset = SCNVector3(
            cameraNode.position.x - focusNode.position.x,
            cameraNode.position.y - focusNode.position.y,
            cameraNode.position.z - focusNode.position.z
        )
        baseRadius = Double(sqrt(offset.x * offset.x + offset.y * offset.y + offset.z * offset.z))
        baseAzimuth = atan2(Double(offset.z), Double(offset.x))
        baseElevation = asin(Double(offset.y) / max(baseRadius, 0.0001))
    }
}

/// SwiftUI wrapper for the SceneKit preview.
struct VirtualSantaPreview: View {
    @Binding var zoomScale: Double
    @Binding var azimuthDegrees: Double
    let renderer: SantaPreviewRenderer
    
    var body: some View {
        VStack(spacing: 10) {
            VStack {
                SceneView(
                    scene: renderer.scene,
                    pointOfView: renderer.cameraNode,
                    options: [.rendersContinuously]
                )
                .cornerRadius(16)
                Slider(value: $azimuthDegrees, in: -90...90) {
                    Text("Rotation").padding(.trailing, 20)
                }
                Slider(value: $zoomScale, in: 0.5...1.5) {
                    Text("Zoom").padding(.trailing, 20)
                }
            }
        }
        .padding()
    }
}

// MARK: - Xcode Preview

struct VirtualSantaPreviewWrapper: View {
    @State private var renderer: SantaPreviewRenderer
    @State private var zoomScale: Double = 0.5
    @State private var azimuthDegrees: Double = -80
    
    init() {
        let r = SantaPreviewRenderer()
        _renderer = State(wrappedValue: r)
    }
    
    private func updateCamera() {
        renderer.updateCamera(
            azimuthDegrees: 360 - azimuthDegrees,
            zoomScale: 2 - zoomScale
        )
    }
    
    private let timer = Timer.publish(every: 1.0 / 30.0, on: .main, in: .common).autoconnect()
    
    var body: some View {
        VirtualSantaPreview(zoomScale: $zoomScale, azimuthDegrees: $azimuthDegrees, renderer: renderer)
            .frame(width: 620, height: 460)
        .onChange(of: zoomScale) { _, _ in updateCamera() }
        .onChange(of: azimuthDegrees) { _, _ in updateCamera() }
        .onReceive(timer) { date in
            let t = date.timeIntervalSinceReferenceDate
            let pose = StateMachine.FigurinePose(
                bodyAngle: sin(t * 0.4) * 25,
                headAngle: sin(t * 0.9) * 15,
                leftHand: (sin(t * 0.8) + 1) / 2,
                rightHand: ((sin(t * 1.1) + 1) / 2) * 0.85
            )
            renderer.apply(pose: pose)
            renderer.applyPerson(relativeOffset: sin(t * 0.5))
            updateCamera()
        }
    }
}

struct VirtualSantaPreview_Previews: PreviewProvider {
    static var previews: some View {
        VirtualSantaPreviewWrapper()
    }
}
