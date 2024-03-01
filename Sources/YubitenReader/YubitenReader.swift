//
//  YubitenReader.swift
//  YubitenReader
//
//  Created by 63rabbits goodman on 2023/12/16.
//

import UIKit
import AudioToolbox

public class YubitenReader: FingerBrailleGuideView {

    // MARK: - Dynamic parameters

    // Touch Spot
    public var showTouchSpot = true
    public var touchSpotColor = UIColor.yellow.withAlphaComponent(0.5)
    public var touchSpotSize = 100
    public var swipeDistance: Int {
        get { return Int(sqrt(swipeSqDistance).rounded()) }
        set { swipeSqDistance = Double(newValue * newValue) }
    }



    // MARK: -

    // Finger Braille Recognition Result
    private var brailleUtf16 : String = "\u{2800}"
    private var brailleSwipe: [SwipeType] = []

    private var brailleHandler: (Recognition, String, [SwipeType]) -> Void = { _,_,_ in } // Void = () = an empty tuple ()

    public enum Recognition {
        case braille
        case swipe
        case failure
    }

    public enum SwipeType: String {
        case swipeUp1       = "swipe U1"    // swipe Up with 1 finger
        case swipeUp2       = "swipe U2"    // swipe Up with 2 fingers
        case swipeUp3       = "swipe U3"    // swipe Up with 3 fingers
        case swipeUp4       = "swipe U4"    // swipe Up with 4 fingers
        case swipeUp5       = "swipe U5"    // swipe Up with 5 fingers

        case swipeDown1     = "swipe D1"    // swipe Down with 1 finger
        case swipeDown2     = "swipe D2"    // swipe Down with 2 fingers
        case swipeDown3     = "swipe D3"    // swipe Down with 3 fingers
        case swipeDown4     = "swipe D4"    // swipe Down with 4 fingers
        case swipeDown5     = "swipe D5"    // swipe Down with 5 fingers

        case swipeLeft1     = "swipe L1"    // swipe Left with 1 finger
        case swipeLeft2     = "swipe L2"    // swipe Left with 2 fingers
        case swipeLeft3     = "swipe L3"    // swipe Left with 3 fingers
        case swipeLeft4     = "swipe L4"    // swipe Left with 4 fingers
        case swipeLeft5     = "swipe L5"    // swipe Left with 5 fingers

        case swipeRight1    = "swipe R1"    // swipe Right with 1 finger
        case swipeRight2    = "swipe R2"    // swipe Right with 2 fingers
        case swipeRight3    = "swipe R3"    // swipe Right with 3 fingers
        case swipeRight4    = "swipe R4"    // swipe Right with 4 fingers
        case swipeRight5    = "swipe R5"    // swipe Right with 5 fingers
    }

    // Label
    public let titleLabel = UILabel()
    let titleDefault = "\u{1F91A} Type Finger Braille."
    let titleFontsize: CGFloat = 24
    let titileColor = UIColor.yellow
    let titileColorLock = UIColor.systemPink

    // Style
    private let kViewBGColor = UIColor.black

    // Guide
    private let defaultSwipeDistance = 50
    private var swipeSqDistance: Double = 0     // swipe distance ^ 2

    // Touch
    private let brailleMaxPoints = 6
    private let sixBraille = "\u{283f}"         // ⠿

    // Touch Spot
    private var touchSpots = [UITouch:SpotView?]()

    // Vibration
    private var in_vibration: Bool = false
    private var vibrationTimer: Timer?
    public var vibrationInterval = 0.1
    public var vibration: Bool {
        get { return in_vibration }
        set {
            // off -> on
            if newValue && in_vibration != newValue {
                vibrationTimer = Timer.scheduledTimer(withTimeInterval: vibrationInterval, repeats: true) {
                    [weak self] timer in
                    let brailleTouch = self!.recognizeBraille()
                    if self!.vibrationBraille.contains(brailleTouch) {
                        AudioServicesPlaySystemSound(self!.vibrationType)
                        if self!.vibrationSound {
                            AudioServicesPlaySystemSound(self!.vibrationSoundID)
                        }
                    }
                }
            }
            // on -> off
            else if in_vibration != newValue {
                vibrationTimer?.invalidate()
            }
            in_vibration = newValue
        }
    }
    private let vibrationType: SystemSoundID = SoundID.ID.Vibration_shortWeak_01.rawValue
    public var vibrationBraille: [String] = []
    public var vibrationSound = false
//    public var vibrationSoundID: SystemSoundID = SoundID.ID.Tink_caf.rawValue
//    public var vibrationSoundID: SystemSoundID = SoundID.ID.acknowledgment_received_caf.rawValue
    public var vibrationSoundID: SystemSoundID = SoundID.ID.Tock_caf.rawValue



    // MARK: - Init

    public init(frame: CGRect, handler: @escaping (Recognition, String, [SwipeType]) -> Void) {
        brailleHandler = handler
        super.init()
        initCommon()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        initCommon()
    }

    private func initCommon() {
        autoresizingMask = [.flexibleWidth, .flexibleHeight]
        backgroundColor = kViewBGColor
        isUserInteractionEnabled = true
        isMultipleTouchEnabled = true
        swipeDistance = swipeDistance <= 0 ? defaultSwipeDistance : swipeDistance
    }

    public override func didMoveToSuperview() {
        super.didMoveToSuperview()
        setupTitle()
    }

    private func kickBrailleHandler(recognition: Recognition, braille: String, swipes: [SwipeType]) {
        brailleHandler(recognition, braille, swipes)
    }



    // MARK: - Orientation lock

    public override func lockIfOrientation(_ ifOrientation: UIInterfaceOrientation, isFlat: Bool) {
        super.lockIfOrientation(ifOrientation, isFlat: isFlat)
        titleLabel.textColor = titileColorLock
    }

    public override func unlockIfOrientation() {
        super.unlockIfOrientation()
        titleLabel.textColor = titileColor
    }

    public override var isLocked: Bool {
        return super.isLocked
    }



    // MARK: - Touch

    public override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches {
            makeTouchSpot(touch: touch)
        }
        bringSubviewToFront(titleLabel)
    }

    public override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches {
            // Move the view(=spot) to the new location.
            if let view = touchSpots[touch] {
                view!.center = touch.location(in: self)
            }
        }
    }

    public override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        // If even one finger touches ended, recognition begins.
        guard touchSpots.count > 0 else { return }

        // recognize swipe
        brailleSwipe = recognizeSwipe()
        if brailleSwipe.count > 0 {
            brailleUtf16 = "s"
            kickBrailleHandler(recognition: .swipe, braille: brailleUtf16, swipes: brailleSwipe)
        }
        else {

            // recognize braille
            brailleUtf16 = recognizeBraille()
            if brailleUtf16.unicodeScalars.count > 0 {
                kickBrailleHandler(recognition: .braille, braille: brailleUtf16, swipes: [])
            }
            else {
                kickBrailleHandler(recognition: .failure, braille: brailleUtf16, swipes: [])
            }
        }

        clearTouches()
    }

    public override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        // If you touch with 6 or more fingers, it will be recognized as U+283f (⠿).
        brailleUtf16 = sixBraille
        kickBrailleHandler(recognition: .braille, braille: brailleUtf16, swipes: [])

        clearTouches()
    }



    // MARK: - Swipe Recognition

    private func recognizeSwipe() -> [SwipeType] {
        var swipeCount = (up:0, down:0, left:0, right:0)
        for (touch, view) in touchSpots {
            let vec = touch.location(in: self) - view!.InitialPosition
            let sqDistance = vec.sqlength

            if sqDistance >= swipeSqDistance {
                if abs(vec.x) > abs(vec.y) {
                    if vec.x >= 0   { swipeCount.right += 1 }
                    else            { swipeCount.left += 1 }
                }
                else {
                    if vec.y >= 0   { swipeCount.down += 1 }
                    else            { swipeCount.up += 1 }
                }
            }
        }

        var swipeArray: [SwipeType] = []
        if swipeCount.up == 1       { swipeArray.append(.swipeUp1)      }
        if swipeCount.up == 2       { swipeArray.append(.swipeUp2)      }
        if swipeCount.up == 3       { swipeArray.append(.swipeUp3)      }
        if swipeCount.up == 4       { swipeArray.append(.swipeUp4)      }
        if swipeCount.up >= 5       { swipeArray.append(.swipeUp5)      }

        if swipeCount.down == 1     { swipeArray.append(.swipeDown1)    }
        if swipeCount.down == 2     { swipeArray.append(.swipeDown2)    }
        if swipeCount.down == 3     { swipeArray.append(.swipeDown3)    }
        if swipeCount.down == 4     { swipeArray.append(.swipeDown4)    }
        if swipeCount.down >= 5     { swipeArray.append(.swipeDown5)    }

        if swipeCount.left == 1     { swipeArray.append(.swipeLeft1)    }
        if swipeCount.left == 2     { swipeArray.append(.swipeLeft2)    }
        if swipeCount.left == 3     { swipeArray.append(.swipeLeft3)    }
        if swipeCount.left == 4     { swipeArray.append(.swipeLeft4)    }
        if swipeCount.left >= 5     { swipeArray.append(.swipeLeft5)    }

        if swipeCount.right == 1    { swipeArray.append(.swipeRight1)   }
        if swipeCount.right == 2    { swipeArray.append(.swipeRight2)   }
        if swipeCount.right == 3    { swipeArray.append(.swipeRight3)   }
        if swipeCount.right == 4    { swipeArray.append(.swipeRight4)   }
        if swipeCount.right >= 5    { swipeArray.append(.swipeRight5)   }

        return swipeArray
    }



    // MARK: - Braille Recognition

    // Procedure for converting Braille to UTF16.
    //
    //  Braille : ⠣ (U+2823)
    //
    //  Step-1: Convert Braille to binary.
    //
    //        <a>     <b>
    //  [1]    1       0    [4]
    //  [2]    1       0    [5]
    //  [3]    0       1    [6]
    //
    //      00    <b>       <a>
    //      00 [6][5][4] [3][2][1]
    //      00    100       011
    //      0010 0011
    //      0x0023
    //
    //  Step-2: Convert binary to braille UTF16 code.
    //
    //      OR( 0x2800, 0x0023 ) -> 0x2823
    //

    private func recognizeBraille() -> String {
        guard touchSpots.count <= brailleMaxPoints else { return "" }

        var touches: [UITouch] = []
        for (touch, _) in touchSpots {
            touches.append(touch)
        }

        // divide the point into left-side and right-side.
        let (leftSidePoints, rightSidePoints) = divideIntoLertRight(touches: touches)
        if (leftSidePoints.count  > brailleMaxPoints / 2) ||
           (rightSidePoints.count > brailleMaxPoints / 2) {
            return ""
        }

        // encode
        let prefixCode: UInt16 = 0x2800
        let leftCode = getLeftCode(points: leftSidePoints)
        let rightCode = getRightCode(points: rightSidePoints)
        var unicode = prefixCode | (leftCode << 3) | rightCode
        if brailleMode == .tableMode {
            // flip 3 bits
            let leftFliped = bitFlip(leftCode, bits: 3)
            let rightFliped = bitFlip(rightCode, bits: 3)
            unicode = prefixCode | (rightFliped << 3) | leftFliped
        }

        return codeToUtf16(code: unicode)
    }

    private func divideIntoLertRight(touches: [UITouch]) -> ([CGPoint], [CGPoint]) {
        var leftSidePoints: [CGPoint] = []
        var rightSidePoints: [CGPoint] = []

        for touch in touches {
            let point = touch.location(in: self)
            if leftGuideImageView.frame.contains(point) {
                leftSidePoints.append(point)
            }
            else if rightGuideImageView.frame.contains(point) {
                rightSidePoints.append(point)
            }
        }

        return (leftSidePoints, rightSidePoints)
    }

    private func getLeftCode(points: [CGPoint]) -> UInt16 {
        let borders = getBorders(coodinateSystem: .upperLeftOrigin)
        let leftUpperBorder = (borders[0], borders[1])
        let leftLowerBorder = (borders[2], borders[3])

        return getCode(points: points, upperBorder: leftUpperBorder, lowerBorder: leftLowerBorder)
    }

    private func getRightCode(points: [CGPoint]) -> UInt16 {
        let borders = getBorders(coodinateSystem: .upperLeftOrigin)
        let rightUpperBorder = (borders[4], borders[5])
        let rightLowerBorder = (borders[6], borders[7])

        return getCode(points: points, upperBorder: rightUpperBorder, lowerBorder: rightLowerBorder)
    }

    private func getCode(points: [CGPoint], upperBorder: (CGPoint, CGPoint), lowerBorder: (CGPoint, CGPoint)) -> UInt16 {
        let count = points.count

        if count <= 0 { return 0b0000 }
        if count >= 3 { return 0b0111 }

        // vote
        var vote = [ 0, 0, 0 ]
        for point in points {
            if GeoUtility.isPointOnRightSide(line: upperBorder, point: point)       { vote[0] += 1 }
            else if GeoUtility.isPointOnLeftSide(line: lowerBorder, point: point)   { vote[2] += 1 }
            else { vote[1] += 1 }
        }

        // encode
        if count == 1 {
            if vote[0] > 0 { return 0b0001 }
            if vote[1] > 0 { return 0b0010 }
            if vote[2] > 0 { return 0b0100 }
        }
        else if count == 2 {
            if vote[0] == 0 { return 0b0110 }
            if vote[2] == 0 { return 0b0011 }
            if vote[1] == 0 { return 0b0101 }
        }

        return 0
    }

    func codeToUtf16(code: UInt16) -> String {
        guard let scalar = UnicodeScalar(code) else { return "?" }
        return String(Character(scalar))
    }

    private func bitFlip(_ value: UInt16, bits: Int = 16) -> UInt16 {
        guard bits > 1 else { return value }

        var v = value
        v = ((v & 0x5555) << 1) | ((v & 0xaaaa) >> 1)
        v = ((v & 0x3333) << 2) | ((v & 0xcccc) >> 2)
        v = ((v & 0x0f0f) << 4) | ((v & 0xf0f0) >> 4)
        v = ((v & 0x00ff) << 8) | ((v & 0xff00) >> 8)

        let shift = (bits <= 16) ? bits : 16
        return v >> (16 - shift)
    }



    // MARK: - Title

    private func setupTitle() {
        titleLabel.text = titleDefault
        titleLabel.font = UIFont.systemFont(ofSize: titleFontsize)
        titleLabel.textColor = titileColor
        titleLabel.textAlignment = .center
        titleLabel.sizeToFit()
        titleLabel.removeFromSuperview()
        self.addSubview(titleLabel)

        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            titleLabel.centerXAnchor.constraint(equalTo: self.centerXAnchor, constant: 0),
            titleLabel.topAnchor.constraint(equalTo: self.topAnchor, constant: 50)
        ])
    }



    // MARK: - Touch Spot

    private func makeTouchSpot(touch: UITouch) {
        let spotView = SpotView()
        spotView.center = touch.location(in: self)
        spotView.InitialPosition = spotView.center
        spotView.backgroundColor = touchSpotColor
        spotView.bounds = CGRect(x: 0, y: 0, width: touchSpotSize, height: touchSpotSize)
        if !showTouchSpot { spotView.isHidden = true }
        addSubview(spotView)

        touchSpots[touch] = spotView
    }

    private func removeTouchSpot(touch: UITouch) {
        if let view = touchSpots[touch]! {
            view.removeFromSuperview()
        }
        touchSpots.removeValue(forKey: touch)
    }

    private func clearTouches() {
        for touch in touchSpots.keys {
            removeTouchSpot(touch: touch)
        }
    }


}

