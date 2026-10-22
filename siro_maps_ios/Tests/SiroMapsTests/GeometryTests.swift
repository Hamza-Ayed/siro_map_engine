import CoreLocation
import XCTest
@testable import SiroMaps

final class GeometryTests: XCTestCase {

    private let amman = CLLocationCoordinate2D(latitude: 31.9539, longitude: 35.9106)

    /// Great-circle distance in metres, as an independent reference.
    private func distance(_ a: CLLocationCoordinate2D, _ b: CLLocationCoordinate2D) -> Double {
        let r = 6_371_000.0
        let dLat = (b.latitude - a.latitude) * .pi / 180
        let dLng = (b.longitude - a.longitude) * .pi / 180
        let h = pow(sin(dLat / 2), 2) + cos(a.latitude * .pi / 180) * cos(b.latitude * .pi / 180) * pow(sin(dLng / 2), 2)
        return 2 * r * asin(sqrt(h))
    }

    func testGeodesicCircleEveryPointIsTheRadiusAway() {
        let ring = geodesicCircle(center: amman, radius: 2000, points: 48)
        XCTAssertEqual(ring.count, 48)
        for point in ring {
            XCTAssertEqual(distance(amman, point), 2000, accuracy: 2)
        }
    }

    func testGeodesicCircleKeepsItsSizeAtHighLatitude() {
        let north = CLLocationCoordinate2D(latitude: 60, longitude: 10)
        for point in geodesicCircle(center: north, radius: 5000) {
            XCTAssertEqual(distance(north, point), 5000, accuracy: 5)
        }
    }

    func testGeodesicLineKeepsItsStartAndEnd() {
        let zarqa = CLLocationCoordinate2D(latitude: 32.0728, longitude: 36.088)
        let line = geodesicLine([amman, zarqa], stepMeters: 5000)
        XCTAssertEqual(line.first?.latitude ?? 0, amman.latitude, accuracy: 1e-9)
        XCTAssertEqual(line.last?.latitude ?? 0, zarqa.latitude, accuracy: 1e-9)
        XCTAssertGreaterThan(line.count, 2)
    }

    /// iOS feeds colours to MapLibre as rgba(), which it parses; verified on the simulator.
    /// Android writes hex with a separate opacity, because its engine does not parse rgba().
    func testCssColorIsRgbaForTheIosEngine() {
        XCTAssertEqual(cssColor(UIColor(red: 17 / 255, green: 34 / 255, blue: 51 / 255, alpha: 0.5)), "rgba(17, 34, 51, 0.500)")
    }

    func testBoundsCoverTheirCorners() {
        let bounds = GMSCoordinateBounds(coordinate: amman, coordinate: CLLocationCoordinate2D(latitude: 32, longitude: 36))
        XCTAssertTrue(bounds.isValid)
        XCTAssertTrue(bounds.contains(amman))
        XCTAssertFalse(bounds.contains(CLLocationCoordinate2D(latitude: 33, longitude: 35.5)))
    }

    func testMutablePathAddsAndRemovesCoordinates() {
        let path = GMSMutablePath()
        path.add(amman)
        path.addLatitude(32, longitude: 36)
        XCTAssertEqual(path.count(), 2)
        path.removeLastCoordinate()
        XCTAssertEqual(path.count(), 1)
        XCTAssertEqual(path.coordinate(at: 0).latitude, amman.latitude, accuracy: 1e-9)
    }

    func testMapStyleRejectsInvalidJSON() {
        XCTAssertThrowsError(try GMSMapStyle(jsonString: "not json"))
        XCTAssertThrowsError(try GMSMapStyle(jsonString: "[1, 2]"))
        XCTAssertNoThrow(try GMSMapStyle(jsonString: #"{"version": 8}"#))
    }

    func testDefaultMarkerImageHasTheRequestedColourSize() {
        let image = GMSMarker.markerImage(with: .systemBlue)
        XCTAssertEqual(image.size.width, 28)
        XCTAssertEqual(image.size.height, 40)
    }

    func testZoomByAtPointKeepsTheFocusFixed() {
        let map = GMSMapView(frame: CGRect(x: 0, y: 0, width: 400, height: 800), camera: GMSCameraPosition(target: amman, zoom: 10))
        let focus = CGPoint(x: 300, y: 200)
        let before = map.projection.coordinate(for: focus)
        map.moveCamera(GMSCameraUpdate.zoomBy(1, at: focus))
        let after = map.projection.coordinate(for: focus)
        XCTAssertEqual(before.latitude, after.latitude, accuracy: 1e-4)
        XCTAssertEqual(before.longitude, after.longitude, accuracy: 1e-4)
    }
}
