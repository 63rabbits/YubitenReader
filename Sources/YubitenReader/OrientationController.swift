//
//  OrientationController.swift
//
//  Created by 63rabbits goodman on 2024/01/05.
//

//  MARK: Note -
//  If the intended rotation does not occur, please check the following.
//    - Xcode > TARGETS > General > Development Info > iPhone Orientation
//    - UIApplicationDelegate.application(_:supportedInterfaceOrientationsFor:)
//    - UIViewController.supportedInterfaceOrientations

import UIKit

class OrientationController {

    var animationsEnabled: Bool = true

    private var windowScene: UIWindowScene?
    private var viewController: UIViewController?
    private var ifOrientationDefaultPlan: [ UIDeviceOrientation: UIInterfaceOrientation ] = [
        .portrait:              .portrait,
        .portraitUpsideDown:    .portraitUpsideDown,
        .landscapeLeft:         .landscapeRight,
        .landscapeRight:        .landscapeLeft,
        .faceUp:                .portrait,
        .faceDown:              .portrait,
        .unknown:               .portrait
    ]
    private var ifOrientationPlan: [ UIDeviceOrientation: UIInterfaceOrientation ]!
    private let orientationHandler: (UIDeviceOrientation, UIInterfaceOrientation) -> Void       // Void = () = an empty tuple ()

    private var lock = false
    private var supportIfOrientationMask = UIInterfaceOrientationMask.all

    private var motionSensor: MotionSensor!
    private let motionUpdateInterval = 0.5  // sec



    // MARK: - init

    init(_ view: UIView, plan: [ UIDeviceOrientation: UIInterfaceOrientation ],
         handler: @escaping (UIDeviceOrientation, UIInterfaceOrientation) -> Void = { _,_  in }) {
        orientationHandler = handler
        windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene
        viewController = getParentViewController(view: view)

        if #unavailable(iOS 16.0) {
            motionSensor = MotionSensor()
        }

        ifOrientationPlan = plan
        setDevOrientationObserver()
    }



    // MARK: - Orientation Observer

    private func setDevOrientationObserver() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(self.devOrientationChanged),
            name: UIDevice.orientationDidChangeNotification,
            object: nil
        )
    }

    @objc func devOrientationChanged() {
        if lock { return }

        let devOrientation = UIDevice.current.orientation
        var ifOrientation = UIInterfaceOrientation.portrait
        if let newIfOrientation = ifOrientationPlan[devOrientation] {
            ifOrientation = newIfOrientation
        }
        else {
            if let orientation = ifOrientationDefaultPlan[devOrientation] {
                ifOrientation = orientation
            }
        }

        setIfOrientation(ifOrientation)
        orientationHandler(devOrientation, ifOrientation)
    }



    // MARK: - Rotation

    func lockIfOrientation(_ ifOrientation: UIInterfaceOrientation) {
        lock = true
        setIfOrientation(ifOrientation)
        orientationHandler(.unknown, ifOrientation)

    }

    var isLocked: Bool {
        return lock
    }

    func unlockIfOrientation() {

        if #unavailable(iOS 16.0) {
            // The following will not be updated unless it rotates, so measure and set it.
            //     UIDevice.current.value(forKey: "orientation")
            if motionSensor.isAbailable {
                motionSensor.startMeasurement(motionUpdateInterval)

                // Since the measurement has just started, it will be delayed to ensure success.
                Thread.sleep(forTimeInterval: 0.5)

                let devOrientation = motionSensor.getDevOrientation()

                var ifOrientation = UIInterfaceOrientation.portrait
                if let orientation = ifOrientationPlan[devOrientation] {
                    ifOrientation = orientation
                }
                else {
                    ifOrientation = ifOrientationDefaultPlan[devOrientation] ??
                                                        UIInterfaceOrientation.portrait
                }
                UIDevice.current.setValue(ifOrientation.rawValue, forKey: "orientation")

                motionSensor.stopMeasurement()
            }
        }

        lock = false
        devOrientationChanged()
    }

    private func setIfOrientation(_ ifOrientation: UIInterfaceOrientation) {
        let save = UIView.areAnimationsEnabled
        if !animationsEnabled { UIView.setAnimationsEnabled(false) }

        guard #available(iOS 16.0, *) else {
//            if let orientation = UIDevice.current.value(forKey: "orientation") as? Int {
//                print(">>> \(orientation)")
//            }
            UIDevice.current.setValue(ifOrientation.rawValue, forKey: "orientation")
            return
        }

        var mask = UIInterfaceOrientationMask.portrait
        switch ifOrientation {
            case .portrait:             mask = .portrait
            case .landscapeLeft:        mask = .landscapeLeft
            case .landscapeRight:       mask = .landscapeRight
            case .portraitUpsideDown:   mask = .portraitUpsideDown
            default:                    break
        }
        supportIfOrientationMask = mask
        viewController?.setNeedsUpdateOfSupportedInterfaceOrientations()

        if !animationsEnabled { UIView.setAnimationsEnabled(save) }
    }

    var supportedIfOrientations: UIInterfaceOrientationMask {
        return supportIfOrientationMask
    }



    // MARK: -

    private func getParentViewController(view: UIView) -> UIViewController? {
        var parent = view as UIResponder
        while let next = parent.next {
            if let viewController = next as? UIViewController { return viewController }
            parent = next
        }
        return nil
    }

    var devOrientation: UIDeviceOrientation {
        return UIDevice.current.orientation
    }

    var IfOrientation: UIInterfaceOrientation? {
        return windowScene?.interfaceOrientation
    }

    static func deviceOrientationTranslator(_ orientation: UIDeviceOrientation) -> String {
        var message = ""
        switch orientation {
            case .unknown:              message = "unknown"
            case .portrait:             message = "portrait"
            case .portraitUpsideDown:   message = "portraitUpsideDown"
            case .landscapeLeft:        message = "landscapeLeft"
            case .landscapeRight:       message = "landscapeRight"
            case .faceUp:               message = "faceUp"
            case .faceDown:             message = "faceDown"
            @unknown default:
                break
        }
        return message
    }

    static func interfaceOrientationTranslator(_ orientation: UIInterfaceOrientation) -> String {
        var message = ""
        switch orientation {
            case .unknown:              message = "unknown"
            case .portrait:             message = "portrait"
            case .portraitUpsideDown:   message = "portraitUpsideDown"
            case .landscapeLeft:        message = "landscapeLeft"
            case .landscapeRight:       message = "landscapeRight"
            @unknown default:
                break
        }
        return message
    }

    static func interfaceOrientationMaskTranslator(_ mask: UIInterfaceOrientationMask, simple: Bool = false) -> String {
        var array: [String] = []

        if simple {
            if mask.contains(.all)                  { return "all" }
            if mask.contains(.allButUpsideDown)     { return "allButUpsideDown" }
            if mask.contains(.landscape)            { return "landscape" }
        }
        if mask.contains(.portrait)             { array.append("portrait") }
        if mask.contains(.portraitUpsideDown)   { array.append("portraitUpsideDown") }
        if mask.contains(.landscapeLeft)        { array.append("landscapeLeft") }
        if mask.contains(.landscapeRight)       { array.append("landscapeRight") }

        return array.joined(separator: ", ")
    }

}

