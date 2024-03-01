//
//  FingerBrailleGuideView.swift
//
//  Created by 63rabbits goodman on 2024/01/02.
//

import UIKit

public class FingerBrailleGuideView: UIView {

    // MARK: - Dynamic parameters

    public var showGuide: Bool {
        get { return in_showGuide }
        set {
            in_showGuide = newValue
            leftGuideImageView.isHidden = !in_showGuide
            rightGuideImageView.isHidden = !in_showGuide
        }
    }

    public var middleFingerWidth: CGFloat {
        get { return middleFingerSize }
        set { middleFingerSize = newValue; drawGuide() }
    }

    public var fingerAngle: CGFloat {            // radian
        get { return touchAngle }
        set { touchAngle = newValue; drawGuide() }
    }

    public var fingerBias: CGPoint {
        get { return touchBias }
        set { touchBias = newValue; drawGuide() }
    }

    public var labelColor: UIColor {
        get { return fingerLabelColor }
        set { fingerLabelColor = newValue; drawGuide() }
    }

    public var indexFingerColor: UIColor {
        get { return finger14Color }
        set { finger14Color = newValue; drawGuide() }
    }

    public var middleFingerColor: UIColor {
        get { return finger25Color }
        set { finger25Color = newValue; drawGuide() }
    }

    public var ringFingerColor: UIColor {
        get { return finger36Color }
        set { finger36Color = newValue; drawGuide() }
    }

    public var borderWidth: CGFloat {
        get { return fingerBorderWidth }
        set { fingerBorderWidth = newValue; drawGuide() }
    }

    public var borderColor: UIColor {
        get { return fingerBorderColor }
        set { fingerBorderColor = newValue; drawGuide() }
    }

    // Guide Spot
    public var guideSpot: Bool {
        get { return in_guideSpot }
        set { in_guideSpot = newValue; drawGuideSpot(brailleMode) }
    }
    public var guideSpotSize: Int {
        get { return in_guideSpotSize }
        set { in_guideSpotSize = newValue; drawGuideSpot(brailleMode) }
    }
    public var guideSpotColor: UIColor {
        get { return in_guideSpotColor }
        set { in_guideSpotColor = newValue; drawGuideSpot(brailleMode) }
    }
    public var guideSpotBraille: String {
        get { return in_guideSpotBraille }
        set { in_guideSpotBraille = newValue; drawGuideSpot(brailleMode) }
    }



    // MARK: -

    private let numOfFingers = 6

    private var in_showGuide = false
    private var touchAngle: CGFloat = 40.0 / 180.0 * CGFloat.pi    // radian
    private var touchBias = CGPoint(x: 0, y: -20)
    private var fingerBorderWidth = CGFloat(1.0)
    private var fingerBorderColor = UIColor.black
    private var finger14Color = UIColor(red: 0.5, green: 0.5, blue: 0.5, alpha: 1)
    private var finger25Color = UIColor(red: 0.4, green: 0.4, blue: 0.4, alpha: 1)
    private var finger36Color = UIColor(red: 0.3, green: 0.3, blue: 0.3, alpha: 1)
    private var fingerLabelColor = UIColor.white

    private var middleFingerSize = CGFloat(0)     // = 0 : automatic computation
    private var finger01HeightConstraint : NSLayoutConstraint!
    private var finger04HeightConstraint : NSLayoutConstraint!

    private var orientationCtrl: OrientationController?
    private var ifOrientationPlan: [ UIDeviceOrientation: UIInterfaceOrientation ] = [
//        .portrait:              .landscapeRight,
//        .portraitUpsideDown:    .landscapeRight,
        .faceUp:                .landscapeRight,
        .faceDown:              .landscapeRight
    ]

    var leftGuideImageView = UIImageView(frame: .zero)
    var rightGuideImageView = UIImageView(frame: .zero)

    private var holdPortraitImage: UIImage!
    private var holdLandscapeImage: UIImage!
    private var tableImage: UIImage!

    enum FingerBorder {     //                +-----+-----+
        case leftUpper      //                |     *.....> right Upper
        case leftLower      //    left Upper  *.....>     |
        case rightUpper     //                |     *.....> right Lower
        case rightLower     //    left Lower  *.....>     |
        case rect           //                +-----+-----+
    }
    var fingerBorder: [ BrailleMode : [ FingerBorder : (CGPoint, CGPoint) ] ] = [:]

    enum FingerID {
        case upper
        case middle
        case lower
    }
    enum Side: CaseIterable {
        case leftSide
        case rightSide
    }
    private var fingerRegion: [ BrailleMode : [ Side : [ FingerID : [CGPoint] ]]] = [:]
    private var guideImage: [ BrailleMode : [ Side : UIImage ] ] = [:]

    enum BrailleMode: CaseIterable {
        case holdModePortrait
        case holdModeLandscape
        case tableMode
    }
    private let fingerLabel: [ BrailleMode : [String] ] = [
        .holdModePortrait : [ "①", "②", "③", "④", "⑤", "⑥"],
        .holdModeLandscape : [ "①", "②", "③", "④", "⑤", "⑥"],
        .tableMode : [ "⑥", "⑤", "④", "③", "②", "①"]
    ]
    private var fingerCentroid : [ BrailleMode : [CGPoint] ] = [:]

    // Guide Spot
    private var in_guideSpot = false
    private var in_guideSpotSize = 80
    private var in_guideSpotColor = UIColor.green.withAlphaComponent(0.5)
    private var in_guideSpotBraille = ""

    private var guideSpots: [SpotView] = []


    var brailleMode: BrailleMode = .holdModePortrait
    private var brailleModeForce: BrailleMode?

    private var windowScene: UIWindowScene?



    // MARK: - init

    init() {
        super.init(frame: .zero)
        initCommon()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        initCommon()
    }

    private func initCommon() {
        self.isUserInteractionEnabled = false
        self.backgroundColor = UIColor.yellow.withAlphaComponent(0)
        in_showGuide = false
        windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene
    }

    public override func didMoveToSuperview() {
        guard let parent = superview else { return }

        self.frame = parent.bounds

//        orientationCtrl = OrientationController(self, plan: ifOrientationPlan)                          // use default function
//        orientationCtrl = OrientationController(self, plan: ifOrientationPlan, handler: { Void in })    // use nop function
//        orientationCtrl = OrientationController(self, plan: ifOrientationPlan, handler: { _ in })       // use nop function
//        orientationCtrl = OrientationController(self, plan: ifOrientationPlan) { (devOrientation: UIDeviceOrientation, ifOrientation: UIInterfaceOrientation) in /* nop */ }
        orientationCtrl = OrientationController(self, plan: ifOrientationPlan, handler: orientationObserver)
        // Disable animation to prevent swipes caused by touch during rotation.
        orientationCtrl?.animationsEnabled = false

        drawGuide()
    }

    public var supportedIfOrientations: UIInterfaceOrientationMask {
        return orientationCtrl?.supportedIfOrientations ?? .all
    }

    enum CoodinateSystem {
        case lowerLeftOrigin    // lower-left-origin
        case upperLeftOrigin    // upper-left-origin
    }
    func getBorders(coodinateSystem: CoodinateSystem) -> [CGPoint] {
        var borders: [CGPoint] = []

        let leftBounds = leftGuideImageView.bounds
        let leftRect = CGPoint(x: leftBounds.width, y: leftBounds.height)
        for type in [ FingerBorder.leftUpper, FingerBorder.leftLower ] {
            let vec = fingerBorder[brailleMode]![type]!
            switch coodinateSystem {
                case .lowerLeftOrigin:
                    borders.append((vec.0 * leftRect).rounded)
                    borders.append((vec.1 * leftRect).rounded)
                case .upperLeftOrigin:
                    borders.append((CGPoint(x: vec.0.x, y: 1 - vec.0.y) * leftRect).rounded)
                    borders.append((CGPoint(x: vec.1.x, y: 1 - vec.1.y) * leftRect).rounded)
            }
        }

        let rightBounds = rightGuideImageView.bounds
        let rightRect = CGPoint(x: rightBounds.width, y: rightBounds.height)
        let delta = CGPoint(x: leftBounds.width, y: 0)
        for type in [ FingerBorder.rightUpper, FingerBorder.rightLower ] {
            let vec = fingerBorder[brailleMode]![type]!
            switch coodinateSystem {
                case .lowerLeftOrigin:
                    borders.append((vec.0 * rightRect + delta).rounded)
                    borders.append((vec.1 * rightRect + delta).rounded)
                case .upperLeftOrigin:
                    borders.append((CGPoint(x: vec.0.x, y: 1 - vec.0.y) * rightRect + delta).rounded)
                    borders.append((CGPoint(x: vec.1.x, y: 1 - vec.1.y) * rightRect + delta).rounded)
            }
        }

        return borders
    } 

    // MARK: - Orientation lock

    private func orientationObserver(devOrientation: UIDeviceOrientation, ifOrientation: UIInterfaceOrientation) {

//        print("Device: \(OrientationController.deviceOrientationTranslator(devOrientation)), " +
//              "Interface: \(OrientationController.interfaceOrientationTranslator(ifOrientation))")

        if let mode = brailleModeForce {
            brailleMode = mode
        }
        else if devOrientation.isFlat {
            brailleMode = .tableMode
        }
        else if ifOrientation.isPortrait {
            brailleMode = .holdModePortrait
        }
        else {
            brailleMode = .holdModeLandscape
        }

        updateGuide(mode: brailleMode)

    }

    func lockIfOrientation(_ ifOrientation: UIInterfaceOrientation, isFlat: Bool) {
        guard let _ = orientationCtrl else { return }

        brailleModeForce = nil
        brailleMode = .holdModePortrait
        if isFlat {
            brailleModeForce = .tableMode
            brailleMode = .tableMode
        }
        updateGuide(mode: brailleMode)
        orientationCtrl!.lockIfOrientation(ifOrientation)
    }

    var isLocked: Bool {
        return orientationCtrl?.isLocked ?? false
    }

    func unlockIfOrientation() {
        brailleModeForce = nil
        orientationCtrl?.unlockIfOrientation()
    }



    // MARK: - Guide

    private func drawGuide() {
        guard let _ = superview else { return }

        middleFingerSize = middleFingerSize > 0 ? middleFingerSize :
            CGFloat.minimum(self.bounds.width, self.bounds.height) / 3  // set default value
        makeGuideView()
        makeAutoLayoutConstraints()
        updateGuide(mode: brailleMode)
    }

    private func updateGuide(mode: BrailleMode) {
        leftGuideImageView.image = nil
        leftGuideImageView.image = guideImage[mode]![.leftSide]
        leftGuideImageView.backgroundColor = UIColor.white
        leftGuideImageView.contentMode = .scaleToFill

        rightGuideImageView.image = nil
        rightGuideImageView.image = guideImage[mode]![.rightSide]
        rightGuideImageView.backgroundColor = UIColor.white
        rightGuideImageView.contentMode = .scaleToFill

        superview?.sendSubviewToBack(leftGuideImageView)
        superview?.sendSubviewToBack(rightGuideImageView)

        drawGuideSpot(mode)
    }

    private func makeGuideView() {
        guard let _ = superview else { return }

        makeFingerBorders()
        makeGuideImage()
    }

    private func makeAutoLayoutConstraints() {
        guard let parent = superview else { return }

        self.translatesAutoresizingMaskIntoConstraints = false
        self.removeConstraints(self.constraints)
        NSLayoutConstraint.activate([
            self.topAnchor.constraint(equalTo: parent.topAnchor),
            self.bottomAnchor.constraint(equalTo: parent.bottomAnchor),
            self.leftAnchor.constraint(equalTo: parent.leftAnchor),
            self.rightAnchor.constraint(equalTo: parent.rightAnchor)
        ])

        leftGuideImageView.removeFromSuperview()
        self.addSubview(leftGuideImageView)
        leftGuideImageView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            leftGuideImageView.topAnchor.constraint(equalTo: self.topAnchor),
            leftGuideImageView.bottomAnchor.constraint(equalTo: self.bottomAnchor),
            leftGuideImageView.leftAnchor.constraint(equalTo: self.leftAnchor),
            leftGuideImageView.widthAnchor.constraint(equalTo: self.widthAnchor, multiplier: 0.5)
        ])

        rightGuideImageView.removeFromSuperview()
        self.addSubview(rightGuideImageView)
        rightGuideImageView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            rightGuideImageView.topAnchor.constraint(equalTo: self.topAnchor),
            rightGuideImageView.bottomAnchor.constraint(equalTo: self.bottomAnchor),
            rightGuideImageView.rightAnchor.constraint(equalTo: self.rightAnchor),
            rightGuideImageView.widthAnchor.constraint(equalTo: self.widthAnchor, multiplier: 0.5)
        ])

    }

    private func makeFingerBorders() {
        guard let parent = superview else { return }

        let length = CGFloat(middleFingerWidth) / 2.0
        var angle = touchAngle
        var w = parent.bounds.width
        var h = parent.bounds.height
        var bias = CGPoint(x: 0, y: 0)

        for mode in BrailleMode.allCases {
            fingerBorder[mode] = [:]

            switch mode {
                case .holdModePortrait:
                    angle = 0
                    bias = CGPoint(x: 0, y: 0)
                    w = min(parent.bounds.width, parent.bounds.height)
                    h = max(parent.bounds.width, parent.bounds.height)
                case .holdModeLandscape:
                    angle = 0
                    bias = CGPoint(x: 0, y: 0)
                    w = max(parent.bounds.width, parent.bounds.height)
                    h = min(parent.bounds.width, parent.bounds.height)
                case .tableMode:
                    angle = touchAngle
                    bias = touchBias
                    w = max(parent.bounds.width, parent.bounds.height)
                    h = min(parent.bounds.width, parent.bounds.height)
            }

            // rect
            let rect = CGRect(x: 0, y: 0, width: (w / 2.0).rounded(), height: h)
            fingerBorder[mode]?[.rect] = ( CGPoint(x: rect.width, y: rect.height), CGPoint.zero )

            // left side
            let center = CGPoint(x: rect.width / 2.0, y: rect.height / 2.0 ) + bias
            let divide = CGPoint(x: rect.width, y: rect.height)

            var origin = CGPoint( x: -sin(angle) * length, y: cos(angle) * length )
            var vec = ( center + origin, center + origin + origin.perpRight )
            var points = getBoxLineSegmentIntersection(rect: rect, lineSeg: vec)
            var borderPoints = GeoUtility.sortPoints(points: points)
            fingerBorder[mode]?[.leftUpper] = ( borderPoints[0] / divide, borderPoints[1] / divide )

            origin = origin.turn
            vec = ( center + origin, center + origin + origin.perpLeft )
            points = getBoxLineSegmentIntersection(rect: rect, lineSeg: vec)
            borderPoints = GeoUtility.sortPoints(points: points)
            fingerBorder[mode]?[.leftLower] = ( borderPoints[0] / divide, borderPoints[1] / divide )

            // right side
            var point = fingerBorder[mode]![.leftUpper]!
            fingerBorder[mode]?[.rightUpper] = (
                CGPoint(x: 1 - point.1.x, y: point.1.y),
                CGPoint(x: 1 - point.0.x, y: point.0.y)
            )
            point = fingerBorder[mode]![.leftLower]!
            fingerBorder[mode]?[.rightLower] = (
                CGPoint(x: 1 - point.1.x, y: point.1.y),
                CGPoint(x: 1 - point.0.x, y: point.0.y)
            )

        }

    }

    private func makeGuideImage() {

        // for finger label
        let labelStyle = NSMutableParagraphStyle()
        labelStyle.alignment = .center
        let fontSize: CGFloat = 60
        let labelPosBias = CGPoint(x: -fontSize / 2 + 3, y: -fontSize / 2 - 5)
        let labelAttr = [
            NSAttributedString.Key.font: UIFont.systemFont(ofSize: fontSize),
            NSAttributedString.Key.paragraphStyle: labelStyle,
            NSAttributedString.Key.foregroundColor: fingerLabelColor
        ]

        makeFingerRegion()

        for mode in BrailleMode.allCases {
            guideImage[mode] = [:]
            fingerCentroid[mode] = []
            for _ in 0..<numOfFingers { fingerCentroid[mode]?.append(CGPoint.zero) }

            let baseRect = fingerBorder[mode]![.rect]!
            let w = baseRect.0.x.rounded()
            let h = baseRect.0.y.rounded()

//            // ignore the scale of the main screen.
//            let renderFormat = UIGraphicsImageRendererFormat()
//            renderFormat.scale = 1.0
//            let renderer = UIGraphicsImageRenderer(size: CGSize(width: w, height: h), format: renderFormat)
            let renderer = UIGraphicsImageRenderer(size: CGSize(width: w, height: h))

            for side in Side.allCases {

                let image = renderer.image {
                    ctx in

                    let context = ctx.cgContext

                    // change coordinate system : LLO -> ULO (upper-left-origin)
                    // core graphics default coordinate system is LLO (lower-left-origin coordinate system).
                    //                context.translateBy(x: 0, y: h)
                    //                context.scaleBy(x: 1, y: -1)

                    context.setStrokeColor(fingerBorderColor.cgColor)
                    context.setLineWidth(fingerBorderWidth)

                    // upper area
                    var region = [ CGPoint.zero ]
                    var centroid: [ FingerID : CGPoint ] = [:]
                    region = fingerRegion[mode]![side]![.upper]!
                    centroid[.upper] = Moments(points: region).centroid
                    context.move(to: region[0])
                    context.addLines(between: region)
                    context.closePath()

                    context.setFillColor(finger14Color.cgColor)
                    context.drawPath(using: .fillStroke)

                    // middle area
                    region = fingerRegion[mode]![side]![.middle]!
                    centroid[.middle] = Moments(points: region).centroid
                    context.move(to: region[0])
                    context.addLines(between: region)
                    context.closePath()

                    context.setFillColor(finger25Color.cgColor)
                    context.drawPath(using: .fillStroke)

                    // lower area
                    region = fingerRegion[mode]![side]![.lower]!
                    centroid[.lower] = Moments(points: region).centroid
                    context.move(to: region[0])
                    context.addLines(between: region)
                    context.closePath()

                    context.setFillColor(finger36Color.cgColor)
                    context.drawPath(using: .fillStroke)

                    // finger label & centroid
                    for i in 0..<6 {
                        let string = NSAttributedString(
                            string: self.fingerLabel[mode]![i],
                            attributes: labelAttr
                        )
                        // finger label
                        switch i {
                            case 0:     if side == .rightSide { string.draw(at: centroid[.upper]! + labelPosBias)   }
                            case 1:     if side == .rightSide { string.draw(at: centroid[.middle]! + labelPosBias)  }
                            case 2:     if side == .rightSide { string.draw(at: centroid[.lower]! + labelPosBias)   }
                            case 3:     if side == .leftSide  { string.draw(at: centroid[.upper]! + labelPosBias)   }
                            case 4:     if side == .leftSide  { string.draw(at: centroid[.middle]! + labelPosBias)  }
                            case 5:     if side == .leftSide  { string.draw(at: centroid[.lower]! + labelPosBias)   }
                            default:    break
                        }
                        // finger centroid
                        switch i {
                            case 0:     if side == .rightSide { fingerCentroid[mode]?[i] = centroid[.upper]!    }
                            case 1:     if side == .rightSide { fingerCentroid[mode]?[i] = centroid[.middle]!   }
                            case 2:     if side == .rightSide { fingerCentroid[mode]?[i] = centroid[.lower]!    }
                            case 3:     if side == .leftSide  { fingerCentroid[mode]?[i] = centroid[.upper]!    }
                            case 4:     if side == .leftSide  { fingerCentroid[mode]?[i] = centroid[.middle]!   }
                            case 5:     if side == .leftSide  { fingerCentroid[mode]?[i] = centroid[.lower]!    }
                            default:    break
                        }

                    }

                }

                switch side {
                    case .leftSide:     guideImage[mode]?[.leftSide] = image
                    case .rightSide:    guideImage[mode]?[.rightSide] = image
                }

            }

        }

    }

    private func makeFingerRegion() {

        for mode in BrailleMode.allCases {

            let baseRect = fingerBorder[mode]![.rect]!
            let rect = CGRect(x: 0, y: 0, width: baseRect.0.x.rounded(), height: baseRect.0.y.rounded())

            let points = [
                CGPoint(x: rect.minX, y: rect.minY),
                CGPoint(x: rect.maxX, y: rect.minY),
                CGPoint(x: rect.maxX, y: rect.maxY),
                CGPoint(x: rect.minX, y: rect.maxY)
            ]

            let multiply = CGPoint(x: rect.width, y: rect.height)
            let leftUpperBorder = (
                (fingerBorder[mode]![.leftUpper]!.0 * multiply).rounded,
                (fingerBorder[mode]![.leftUpper]!.1 * multiply).rounded
            )
            let leftLowerBorder = (
                (fingerBorder[mode]![.leftLower]!.0 * multiply).rounded,
                (fingerBorder[mode]![.leftLower]!.1 * multiply).rounded
            )

            fingerRegion[mode] = [ 
                .leftSide: [ .upper:[], .middle :[], .lower:[] ],
                .rightSide: [ .upper:[], .middle :[], .lower:[] ]
            ]

            fingerRegion[mode]?[.leftSide]?[.upper]?.append(leftUpperBorder.0)
            fingerRegion[mode]?[.leftSide]?[.upper]?.append(leftUpperBorder.1)

            fingerRegion[mode]?[.leftSide]?[.lower]?.append(leftLowerBorder.0)
            fingerRegion[mode]?[.leftSide]?[.lower]?.append(leftLowerBorder.1)

            fingerRegion[mode]?[.leftSide]?[.middle]?.append(leftUpperBorder.0)
            fingerRegion[mode]?[.leftSide]?[.middle]?.append(leftUpperBorder.1)
            fingerRegion[mode]?[.leftSide]?[.middle]?.append(leftLowerBorder.0)
            fingerRegion[mode]?[.leftSide]?[.middle]?.append(leftLowerBorder.1)

            for point in points {
                if GeoUtility.isPointOnLeftSide(line: leftUpperBorder, point: point) {
                    fingerRegion[mode]?[.leftSide]?[.upper]?.append(point.rounded)
                }
                if GeoUtility.isPointOnRightSide(line: leftUpperBorder, point: point, online: true) &&
                    GeoUtility.isPointOnLeftSide(line: leftLowerBorder, point: point, online: true) {
                    fingerRegion[mode]?[.leftSide]?[.middle]?.append(point.rounded)
                }
                if GeoUtility.isPointOnRightSide(line: leftLowerBorder, point: point) {
                    fingerRegion[mode]?[.leftSide]?[.lower]?.append(point.rounded)
                }
            }

            var region = fingerRegion[mode]![.leftSide]![.upper]!
            fingerRegion[mode]?[.leftSide]?[.upper] =
                flipPoints( points: GeoUtility.sortPoints(points: region), rect: rect, flips: [ .vertical ] )
            fingerRegion[mode]?[.rightSide]?[.upper] =
                flipPoints( points: GeoUtility.sortPoints(points: region), rect: rect, flips: [ .vertical, .horizontal ] )

            region = fingerRegion[mode]![.leftSide]![.middle]!
            fingerRegion[mode]?[.leftSide]?[.middle] =
                flipPoints( points: GeoUtility.sortPoints(points: region), rect: rect, flips: [ .vertical ] )
            fingerRegion[mode]?[.rightSide]?[.middle] =
                flipPoints( points: GeoUtility.sortPoints(points: region), rect: rect, flips: [ .vertical, .horizontal ] )

            region = fingerRegion[mode]![.leftSide]![.lower]!
            fingerRegion[mode]?[.leftSide]?[.lower] =
                flipPoints( points: GeoUtility.sortPoints(points: region), rect: rect, flips: [ .vertical ] )
            fingerRegion[mode]?[.rightSide]?[.lower] =
                flipPoints( points: GeoUtility.sortPoints(points: region), rect: rect, flips: [ .vertical, .horizontal ] )

        }

    }

    enum Flip {
        case vertical
        case horizontal
    }
    private func flipPoints(points: [CGPoint], rect: CGRect, flips: [ Flip ]) -> [CGPoint] {
        let w = rect.width
        let h = rect.height

        var srcPoints = points
        var dstPoints = points
        for flip in flips {
            switch flip {
                case .vertical:   dstPoints = srcPoints.map { CGPoint( x: $0.x, y: h - $0.y) }
                case .horizontal: dstPoints = srcPoints.map { CGPoint( x: w - $0.x, y: $0.y) }
            }
            srcPoints = dstPoints
        }

        return dstPoints
    }

    private func getBoxLineSegmentIntersection(rect: CGRect, lineSeg: (CGPoint, CGPoint)) -> [CGPoint] {
        var intersections: [CGPoint] = []

        // get edges
        var edgeStart = CGPoint(x: Double(rect.minX), y: Double(rect.minY))
        var edgeEnd = edgeStart
        for i in 0..<4 {
            switch i {
                case 0: edgeEnd = CGPoint(x: Double(rect.maxX), y: Double(rect.minY))
                case 1: edgeEnd = CGPoint(x: Double(rect.maxX), y: Double(rect.maxY))
                case 2: edgeEnd = CGPoint(x: Double(rect.minX), y: Double(rect.maxY))
                case 3: edgeEnd = CGPoint(x: Double(rect.minX), y: Double(rect.minY))
                default: break
            }

            if let crossPoint = GeoUtility.geLineSegmentIntersection(lineSeg1: (edgeStart, edgeEnd), lineSeg2: lineSeg, inner: false) {
                if ((rect.minX...rect.maxX).contains(crossPoint.x) &&
                    (rect.minY...rect.maxY).contains(crossPoint.y)) {
                    intersections.append(crossPoint)
                }
            }
            edgeStart = edgeEnd
        }

        return intersections
    }



    // MARK: - Guide Spot

    private func drawGuideSpot(_ mode: BrailleMode) {
        guard let _ = superview else { return }

        clearGuideSpots()
        if !in_guideSpot || in_guideSpotBraille.count <= 0 { return }

        let code = UInt16(in_guideSpotBraille.unicodeScalars.first!.value)
        if code < 0x2800 || 0x283f < code { return }

        let centroid = getCentroid(mode: mode)
        for i in 0..<numOfFingers {
            let mask: UInt16 = 1 << i
            if (code & mask) > 0 {
                makeGuideSpot(centroid[i])
            }
        }
    }

    private func makeGuideSpot(_ centroid: CGPoint) {
        let spotView = SpotView()
        spotView.center = centroid
        spotView.backgroundColor = in_guideSpotColor
        spotView.bounds = CGRect(x: 0, y: 0, width: in_guideSpotSize, height: in_guideSpotSize)
        addSubview(spotView)

        guideSpots.append(spotView)
    }

    private func clearGuideSpots() {
        while guideSpots.count > 0 {
            let view = guideSpots.removeFirst()
            view.removeFromSuperview()
        }
    }
    
    private func getCentroid(mode: BrailleMode) -> [CGPoint] {
        var centroid = fingerCentroid[brailleMode]!

        // Problem with this code:
        //   if it is processed when the size of the view is changing,
        //   the display position will be incorrect.
//        for i in 0..<numOfFingers {
//            if i < 3    { centroid[i] = self.convert(centroid[i], from: rightGuideImageView) }
//            else        { centroid[i] = self.convert(centroid[i], from: leftGuideImageView) }
//        }

//        let width = leftGuideImageView.image!.size.width
        let w = min(self.bounds.width, self.bounds.height)
        let h = max(self.bounds.width, self.bounds.height)
        var width = w / 2
        if mode != .holdModePortrait { width = h / 2 }
        let delta = CGPoint(x: width, y: 0)
        for i in 0..<(numOfFingers / 2) {
            centroid[i] = centroid[i] + delta
        }

        // reverse centroid array for Table mode
        //      ⑥⑤④③②① -> ①②③④⑤⑥
        //
        //          Index          Hold mode        Table mode
        //        +---+---+        +---+---+        +---+---+
        //        | 3 | 0 |        | 4 | 1 |        | 3 | 6 |
        //        +---+---+        +---+---+        +---+---+
        //        | 4 | 1 |        | 5 | 2 |        | 2 | 5 |
        //        +---+---+        +---+---+        +---+---+
        //        | 5 | 2 |        | 6 | 3 |        | 1 | 4 |
        //        +---+---+        +---+---+        +---+---+
        //
        if brailleMode == .tableMode {
            centroid = centroid.reversed()
        }

        return centroid
    }



    // MARK: -

    public var devOrientation: UIDeviceOrientation? {
        return orientationCtrl?.devOrientation
    }

    public var ifOrientation: UIInterfaceOrientation? {
        return orientationCtrl?.IfOrientation
    }

}
