import CoreLocation
import XCTest
@testable import SiroMaps

/// Checks the pieces that mirror Google's utilities against known answers.
final class GoogleParityTests: XCTestCase {

    /// The example from Google's polyline documentation.
    private let encoded = "_p~iF~ps|U_ulLnnqC_mqNvxq`@"

    func testEncodedPathDecodesToGoogleDocumentationPoints() throws {
        let path = try XCTUnwrap(GMSPath(fromEncodedPath: encoded))
        XCTAssertEqual(path.count(), 3)
        XCTAssertEqual(path.coordinate(at: 0).latitude, 38.5, accuracy: 1e-5)
        XCTAssertEqual(path.coordinate(at: 0).longitude, -120.2, accuracy: 1e-5)
        XCTAssertEqual(path.coordinate(at: 2).latitude, 43.252, accuracy: 1e-5)
        XCTAssertEqual(path.coordinate(at: 2).longitude, -126.453, accuracy: 1e-5)
    }

    func testEncodedPathRoundTrips() throws {
        let path = try XCTUnwrap(GMSPath(fromEncodedPath: encoded))
        XCTAssertEqual(path.encodedPath(), encoded)
    }

    func testInvalidEncodedPathIsNil() {
        XCTAssertNil(GMSPath(fromEncodedPath: "\u{1}"))
    }

    func testDistanceHeadingAndOffsetAgree() {
        let amman = CLLocationCoordinate2D(latitude: 31.9539, longitude: 35.9106)
        let moved = GMSGeometryOffset(amman, 5_000, 90)
        XCTAssertEqual(GMSGeometryDistance(amman, moved), 5_000, accuracy: 1)
        XCTAssertEqual(GMSGeometryHeading(amman, moved), 90, accuracy: 0.1)
    }

    func testLengthOfTwoLegs() {
        let a = CLLocationCoordinate2D(latitude: 0, longitude: 0)
        let b = CLLocationCoordinate2D(latitude: 0, longitude: 1)
        let c = CLLocationCoordinate2D(latitude: 1, longitude: 1)
        let path = GMSPath(coordinates: [a, b, c])
        XCTAssertEqual(GMSGeometryLength(path), GMSGeometryDistance(a, b) + GMSGeometryDistance(b, c), accuracy: 1e-6)
    }

    func testAreaOfOneDegreeSquareAtTheEquator() {
        let square = GMSPath(coordinates: [
            CLLocationCoordinate2D(latitude: 0, longitude: 0),
            CLLocationCoordinate2D(latitude: 0, longitude: 1),
            CLLocationCoordinate2D(latitude: 1, longitude: 1),
            CLLocationCoordinate2D(latitude: 1, longitude: 0),
        ])
        // About 111.2 km by 111.2 km.
        XCTAssertEqual(GMSGeometryArea(square), 1.2364e10, accuracy: 1e8)
    }

    func testContainsAndOnPath() {
        let square = GMSPath(coordinates: [
            CLLocationCoordinate2D(latitude: 0, longitude: 0),
            CLLocationCoordinate2D(latitude: 0, longitude: 2),
            CLLocationCoordinate2D(latitude: 2, longitude: 2),
            CLLocationCoordinate2D(latitude: 2, longitude: 0),
        ])
        XCTAssertTrue(GMSGeometryContainsLocation(CLLocationCoordinate2D(latitude: 1, longitude: 1), square, false))
        XCTAssertFalse(GMSGeometryContainsLocation(CLLocationCoordinate2D(latitude: 3, longitude: 1), square, false))
        XCTAssertTrue(GMSGeometryIsLocationOnPathTolerance(CLLocationCoordinate2D(latitude: 0.0001, longitude: 1), square, false, 50))
    }

    func testInterpolateHalfway() {
        let a = CLLocationCoordinate2D(latitude: 0, longitude: 0)
        let b = CLLocationCoordinate2D(latitude: 0, longitude: 10)
        let mid = GMSGeometryInterpolate(a, b, 0.5)
        XCTAssertEqual(mid.longitude, 5, accuracy: 1e-6)
    }

    func testBoundsIntersectAndPath() {
        let a = GMSCoordinateBounds(coordinate: CLLocationCoordinate2D(latitude: 0, longitude: 0), coordinate: CLLocationCoordinate2D(latitude: 2, longitude: 2))
        let b = GMSCoordinateBounds(coordinate: CLLocationCoordinate2D(latitude: 1, longitude: 1), coordinate: CLLocationCoordinate2D(latitude: 3, longitude: 3))
        let c = GMSCoordinateBounds(coordinate: CLLocationCoordinate2D(latitude: 5, longitude: 5), coordinate: CLLocationCoordinate2D(latitude: 6, longitude: 6))
        XCTAssertTrue(a.intersects(b))
        XCTAssertFalse(a.intersects(c))
        let grown = a.includingPath(GMSPath(coordinates: [CLLocationCoordinate2D(latitude: 9, longitude: 9)]))
        XCTAssertEqual(grown.northEast.latitude, 9)
    }

    func testServicesAcceptAKey() {
        XCTAssertTrue(GMSServices.provideAPIKey("any-key"))
    }

    func testStyleSpansKeepTheirSegments() {
        let span = GMSStyleSpan(color: .red, segments: 2.5)
        XCTAssertEqual(span.segments, 2.5)
        XCTAssertEqual(GMSStyleSpan(color: .blue).segments, 1)
    }
}
