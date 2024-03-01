//
//  MotionSensor.swift
//
//  Created by 63rabbits goodman on 2024/02/18.
//

import UIKit
import CoreMotion

class MotionSensor {

    private var motionManager: CMMotionManager!
    var isAbailable: Bool {
        get { return motionManager.isDeviceMotionAvailable }
    }

    private let motionHandler: (CMDeviceMotion?, Error?) -> Void


    init(_ handler: @escaping (CMDeviceMotion?, Error?) -> Void = { _,_ in }) {
        motionHandler = handler
        motionManager = CMMotionManager()
    }

    func startMeasurement(_ updateInterval: Double) {

        motionManager.deviceMotionUpdateInterval = updateInterval
        motionManager.startDeviceMotionUpdates(
            using: .xArbitraryZVertical,
            to: OperationQueue.current!,
            withHandler: motionHandler
        )
    }

    func stopMeasurement() {
        motionManager.stopDeviceMotionUpdates()
    }

    func getAttitude() -> (Double, Double, Double)? {   // -π ~ +π rad.
        if let attitude = motionManager.deviceMotion?.attitude {
            return (attitude.pitch, attitude.roll, attitude.yaw)
        }
        return nil
    }

    let criterionAngle = 30/180 * Double.pi
    func getDevOrientation() -> UIDeviceOrientation {
        let portraiteRange = (criterionAngle, Double.pi)
        let landscapeRange = (criterionAngle, Double.pi - criterionAngle)

        var orientation = UIDeviceOrientation.portrait

        guard let (pitch, roll, _) = getAttitude() else { return orientation }

        if abs(pitch) >= portraiteRange.0 {
            if pitch > 0                        { orientation = UIDeviceOrientation.portrait }
            else                                { orientation = UIDeviceOrientation.portraitUpsideDown }
        }
        else if abs(roll) >= landscapeRange.0 && 
                abs(roll) <= landscapeRange.1 {
            if roll < 0                         { orientation = UIDeviceOrientation.landscapeLeft }
            else                                { orientation = UIDeviceOrientation.landscapeRight }
        }
        else if abs(roll) < landscapeRange.0    { orientation = UIDeviceOrientation.faceUp }
        else                                    { orientation = UIDeviceOrientation.faceDown }

        return orientation
    }


}
