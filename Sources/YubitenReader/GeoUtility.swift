//
//  GeoUtility.swift
//
//  Created by 63rabbits goodman on 2024/02/06.
//

import Foundation

class GeoUtility {

    static func innerProduct(line1: ( CGPoint, CGPoint ), line2: ( CGPoint, CGPoint )) -> Double {
        let p1 = line1.1 - line1.0
        let p2 = line2.1 - line2.0
        // inner product = x1x2 + y1y2
        return p1 & p2
    }

    static func crossProduct(line1: ( CGPoint, CGPoint ), line2: ( CGPoint, CGPoint )) -> Double {
        let p1 = line1.1 - line1.0
        let p2 = line2.1 - line2.0
        // cross product = x1y2 - x2y1
        return p1 % p2
    }

    static func isPointOnLeftSide(line: ( CGPoint, CGPoint ), point: CGPoint, online: Bool = false) -> Bool {
        let alpha = crossProduct(line1: line, line2: (line.0, point))
        if online {
            return alpha >= 0
        }
        return alpha > 0
    }

    static func isPointOnRightSide(line: ( CGPoint, CGPoint ), point: CGPoint, online: Bool = false) -> Bool {
        if online {
            return !isPointOnLeftSide(line: line, point: point)
        }
        return !isPointOnLeftSide(line: line, point: point, online: true)
    }

    static func sortPoints(points: [ CGPoint ], ccw: Bool = true) -> [CGPoint] {
        guard points.count > 1 else { return points }

        // select leftmost point
        var base = points[0]
        for i in 1..<points.count {
            let p = points[i]
            if p.x < base.x { base = p }
            else if p.x == base.x {
                if p.y < base.y { base = p }
            }
        }

        return points.sorted {
            var alpha = GeoUtility.crossProduct(line1: (base, $0), line2: (base, $1))
            if !ccw { alpha = -alpha }
            if alpha > 0 {
                return true
            }
            else if alpha == 0 {
                return ($0 - base).sqlength < ($1 - base).sqlength
            }
            return false
        }

    }

    static func geLineSegmentIntersection(lineSeg1: (CGPoint, CGPoint), lineSeg2: (CGPoint, CGPoint), inner: Bool = true) -> CGPoint? {
        let (p1, p2) = lineSeg1
        let (p3, p4) = lineSeg2

        // check parallel
        let d = (p2.x - p1.x) * (p4.y - p3.y) - (p2.y - p1.y) * (p4.x - p3.x)   // cross product
        if (d == 0) { return nil }

        // check inner crossing
        let s = ((p3.x - p1.x) * (p4.y - p3.y) - (p3.y - p1.y) * (p4.x - p3.x)) / d
        if (inner && (s < 0 || s > 1)) { return nil }

        // get intersection and round off
        let x = round(((1 - s) * p1.x + s * p2.x) * 10) / 10
        let y = round(((1 - s) * p1.y + s * p2.y) * 10) / 10

        return CGPoint(x: x, y: y)
    }



}

class Moments {

    let points: [CGPoint]!

    private var m00 = 0.0
    private var m01 = 0.0
    private var m10 = 0.0
    private var m11 = 0.0
    private var m02 = 0.0
    private var m20 = 0.0

    init(points: [CGPoint]) {
        self.points = points

        // Calc Moment : Mij = ∑∑( x^i * y^j )
        m00 = Double(points.count)
        for point in points {
            m01 += point.y
            m10 += point.x
            m11 += point.x * point.y
            m02 += point.y * point.y
            m20 += point.x * point.x
        }
    }

    var centroid: CGPoint {
        return CGPoint(x: m10 / m00, y: m01 / m00)
    }

    var area: Double {
        return Double(points.count)
    }

    var inertia: Double {
        return m20 + m02
    }

    var principalAxisOfInertia: Double {
        return atan( (2 * m11) / (m20 - m02) ) / 2.0
    }

    var circularity: Double {
        return (2 * CGFloat.pi) / (m00 * m00) * inertia
    }

}



extension CGPoint { // add Vector function

    static func + (left: CGPoint, right: CGPoint) -> CGPoint {
        return CGPoint(x: left.x + right.x, y: left.y + right.y)
    }

    static func - (left: CGPoint, right: CGPoint) -> CGPoint {
        return CGPoint(x: left.x - right.x, y: left.y - right.y)
    }

    static func * (left: CGPoint, right: Double) -> CGPoint {   // multiplication
        return CGPoint(x: left.x * right, y: left.y * right)
    }

    static func * (left: CGPoint, right: CGPoint) -> CGPoint {   // multiplication
        return CGPoint(x: left.x * right.x, y: left.y * right.y)
    }

    static func / (left: CGPoint, right: Double) -> CGPoint {   // division
        return CGPoint(x: left.x / right, y: left.y / right)
    }

    static func / (left: CGPoint, right: CGPoint) -> CGPoint {   // division
        return CGPoint(x: left.x / right.x, y: left.y / right.y)
    }

    static func & (left: CGPoint, right: CGPoint) -> Double {   // inner product
        return left.x * right.x + left.y * right.y
    }

    static func % (left: CGPoint, right: CGPoint) -> Double {   // cross product
        return left.x * right.y - right.x * left.y
    }

    var sqlength: Double {    // Squared length
        return self.x * self.x + self.y * self.y
    }

    var length: Double {
        return sqrt(self.sqlength)
    }

    var unit: CGPoint {
        return CGPoint(x: self.x / self.length, y: self.y / self.length)
    }

    var perpRight: CGPoint {  // Right Perpendicular
        return CGPoint(x: self.y, y: -self.x)   // CW
    }

    var perpLeft: CGPoint {  // Left Perpendicular
        return CGPoint(x: -self.y, y: self.x)   // CCW
    }

    var turn: CGPoint {
        return CGPoint(x: -self.x, y: -self.y)
    }

    var rounded: CGPoint {
        return CGPoint(x: self.x.rounded(), y: self.y.rounded())
    }

}
