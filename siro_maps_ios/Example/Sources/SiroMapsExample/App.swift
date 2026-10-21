import CoreLocation
import SiroMaps
import SwiftUI
import UIKit

@main
struct SiroMapsExampleApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

/// The map with a row of controls: day, night and 3D, as the Android sample.
struct ContentView: View {
    var body: some View {
        ZStack(alignment: .topTrailing) {
            SiroMapRepresentable()
                .ignoresSafeArea()
            VStack(spacing: 8) {
                Button("Day") {
                    ExampleMap.shared?.mapType = .normal
                    ExampleMap.shared?.mapStyle = nil
                }
                Button("Night") {
                    ExampleMap.shared?.mapStyle = GMSMapStyle(siroStyleURL: SiroStyleURL.night)
                }
                Button("3D") {
                    ExampleMap.shared?.mapType = .terrain
                }
            }
            .buttonStyle(.borderedProminent)
            .padding()
        }
    }
}

/// The map the controls drive. The sample has one map, so a shared reference is enough.
@MainActor
enum ExampleMap {
    static weak var shared: GMSMapView?
}

struct SiroMapRepresentable: UIViewRepresentable {

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeUIView(context: Context) -> GMSMapView {
        let amman = CLLocationCoordinate2D(latitude: 31.9539, longitude: 35.9106)
        let zarqa = CLLocationCoordinate2D(latitude: 32.0728, longitude: 36.0880)
        let map = GMSMapView(
            frame: .zero,
            camera: GMSCameraPosition(target: CLLocationCoordinate2D(latitude: 32.01, longitude: 35.99), zoom: 9.6)
        )
        map.delegate = context.coordinator
        ExampleMap.shared = map

        let ammanMarker = GMSMarker(position: amman)
        ammanMarker.title = "Amman"
        ammanMarker.snippet = "Capital of Jordan"
        ammanMarker.map = map

        let zarqaMarker = GMSMarker(position: zarqa)
        zarqaMarker.title = "Zarqa"
        zarqaMarker.snippet = "Hold to drag"
        zarqaMarker.icon = GMSMarker.markerImage(with: .systemBlue)
        zarqaMarker.isDraggable = true
        zarqaMarker.map = map

        let route = GMSPolyline(path: GMSPath(coordinates: [amman, zarqa]))
        route.strokeWidth = 6
        route.strokeColor = UIColor(red: 0.1, green: 0.46, blue: 0.82, alpha: 1)
        route.isTappable = true
        route.map = map

        let triangle = GMSPolygon(path: GMSPath(coordinates: [
            CLLocationCoordinate2D(latitude: 31.97, longitude: 35.85),
            CLLocationCoordinate2D(latitude: 31.99, longitude: 35.92),
            CLLocationCoordinate2D(latitude: 31.94, longitude: 35.93),
        ]))
        triangle.fillColor = UIColor.green.withAlphaComponent(0.27)
        triangle.strokeColor = .systemGreen
        triangle.strokeWidth = 3
        triangle.isTappable = true
        triangle.map = map

        let circle = GMSCircle(position: amman, radius: 2000)
        circle.fillColor = UIColor.red.withAlphaComponent(0.13)
        circle.strokeColor = .systemRed
        circle.strokeWidth = 3
        circle.isTappable = true
        circle.map = map

        return map
    }

    func updateUIView(_ uiView: GMSMapView, context: Context) {}
}

/// Logs the taps and drags, so each callback can be checked on the simulator.
final class Coordinator: NSObject, GMSMapViewDelegate {

    func mapView(_ mapView: GMSMapView, didTapAt coordinate: CLLocationCoordinate2D) {
        print("SIRO didTapAt \(coordinate.latitude), \(coordinate.longitude)")
    }

    func mapView(_ mapView: GMSMapView, didLongPressAt coordinate: CLLocationCoordinate2D) {
        print("SIRO didLongPressAt \(coordinate.latitude), \(coordinate.longitude)")
    }

    func mapView(_ mapView: GMSMapView, didTap marker: GMSMarker) -> Bool {
        print("SIRO didTap marker \(marker.title ?? "-")")
        return false
    }

    func mapView(_ mapView: GMSMapView, didTap overlay: GMSOverlay) {
        print("SIRO didTap overlay")
    }

    func mapView(_ mapView: GMSMapView, didTapInfoWindowOf marker: GMSMarker) {
        print("SIRO didTapInfoWindowOf \(marker.title ?? "-")")
    }

    func mapView(_ mapView: GMSMapView, didBeginDragging marker: GMSMarker) {
        print("SIRO didBeginDragging \(marker.title ?? "-")")
    }

    func mapView(_ mapView: GMSMapView, didEndDragging marker: GMSMarker) {
        print("SIRO didEndDragging \(marker.position.latitude), \(marker.position.longitude)")
    }
}
