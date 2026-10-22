import CoreLocation
import MapLibre
import UIKit

/// Turns the map's overlays into style sources and layers, the way the Android SDK does.
///
/// Sources and layers are rebuilt from the overlays on every `refresh`. Fills and lines
/// read their colour and width from each feature, so one layer draws them all.
internal final class Renderer {

    private enum Name {
        static let fillSource = "siro-fill-source"
        static let fillLayer = "siro-fill-layer"
        static let lineSource = "siro-line-source"
        static let lineLayer = "siro-line-layer"
        static let markerSource = "siro-marker-source"
        static let markerLayer = "siro-marker-layer"
    }

    private static let defaultPinName = "siro-default-pin"
    private static let defaultPin = GMSMarker.markerImage(with: nil)

    private weak var map: GMSMapView?
    private var style: MLNStyle?
    private var fillSource: MLNShapeSource?
    private var lineSource: MLNShapeSource?
    private var markerSource: MLNShapeSource?
    /// The icon names already added to the current style.
    private var images = Set<String>()

    init(map: GMSMapView) {
        self.map = map
    }

    /// Adds the sources and layers to a freshly loaded style, then draws the overlays.
    func attach(to style: MLNStyle) {
        self.style = style
        images.removeAll()

        let fills = MLNShapeSource(identifier: Name.fillSource, shape: nil, options: nil)
        let lines = MLNShapeSource(identifier: Name.lineSource, shape: nil, options: nil)
        let markers = MLNShapeSource(identifier: Name.markerSource, shape: nil, options: nil)
        style.addSource(fills)
        style.addSource(lines)
        style.addSource(markers)
        fillSource = fills
        lineSource = lines
        markerSource = markers

        let fillLayer = MLNFillStyleLayer(identifier: Name.fillLayer, source: fills)
        fillLayer.fillColor = NSExpression(forKeyPath: "color")

        let lineLayer = MLNLineStyleLayer(identifier: Name.lineLayer, source: lines)
        lineLayer.lineColor = NSExpression(forKeyPath: "color")
        lineLayer.lineWidth = NSExpression(forKeyPath: "width")
        lineLayer.lineCap = NSExpression(forConstantValue: "round")
        lineLayer.lineJoin = NSExpression(forConstantValue: "round")

        // Fills and lines go under the map's labels, so the labels stay readable.
        let labels = style.layers.first { $0 is MLNSymbolStyleLayer }
        for layer in [fillLayer, lineLayer] {
            if let labels {
                style.insertLayer(layer, below: labels)
            } else {
                style.addLayer(layer)
            }
        }

        let markerLayer = MLNSymbolStyleLayer(identifier: Name.markerLayer, source: markers)
        markerLayer.iconImageName = NSExpression(forKeyPath: "icon")
        markerLayer.iconAnchor = NSExpression(forKeyPath: "anchor")
        markerLayer.iconRotation = NSExpression(forKeyPath: "rotation")
        markerLayer.iconOpacity = NSExpression(forKeyPath: "opacity")
        markerLayer.iconAllowsOverlap = NSExpression(forConstantValue: true)
        markerLayer.iconIgnoresPlacement = NSExpression(forConstantValue: true)
        style.addLayer(markerLayer)

        refresh()
    }

    /// Rebuilds the features from the map's overlays.
    func refresh() {
        guard let style, let map else { return }
        var fills: [MLNShape] = []
        var lines: [MLNShape] = []
        var markers: [MLNShape] = []

        for overlay in map.overlays.sorted(by: { $0.zIndex < $1.zIndex }) {
            let id = Renderer.identifier(for: overlay)
            switch overlay {
            case let marker as GMSMarker:
                markers.append(markerFeature(marker, id: id, style: style))
            case let polyline as GMSPolyline:
                guard let path = polyline.path?.coordinates else { break }
                let coordinates = polyline.geodesic ? geodesicLine(path) : path
                if let spans = polyline.spans, !spans.isEmpty {
                    for piece in styledPieces(of: coordinates, spans: spans) {
                        appendLine(piece.coordinates, id: id, kind: "polyline", color: piece.color, width: polyline.strokeWidth, to: &lines)
                    }
                } else {
                    appendLine(coordinates, id: id, kind: "polyline", color: polyline.strokeColor, width: polyline.strokeWidth, to: &lines)
                }
            case let polygon as GMSPolygon:
                guard let outer = polygon.path?.coordinates, outer.count >= 3 else { break }
                let holes = (polygon.holes ?? []).map { $0.coordinates }.filter { $0.count >= 3 }
                let closedOuter = polygon.geodesic ? geodesicLine(outer + [outer[0]]) : outer + [outer[0]]
                if let fill = polygon.fillColor, let feature = polygonFeature(outer: closedOuter, holes: holes, id: id, kind: "polygon", fill: fill) {
                    fills.append(feature)
                }
                if let stroke = polygon.strokeColor {
                    appendLine(closedOuter, id: id, kind: "polygon", color: stroke, width: polygon.strokeWidth, to: &lines)
                    for hole in holes {
                        appendLine(hole + [hole[0]], id: id, kind: "polygon", color: stroke, width: polygon.strokeWidth, to: &lines)
                    }
                }
            case let circle as GMSCircle:
                guard circle.radius > 0 else { break }
                let ring = geodesicCircle(center: circle.position, radius: circle.radius)
                let closed = ring + [ring[0]]
                if let fill = circle.fillColor, let feature = polygonFeature(outer: closed, holes: [], id: id, kind: "circle", fill: fill) {
                    fills.append(feature)
                }
                if let stroke = circle.strokeColor {
                    appendLine(closed, id: id, kind: "circle", color: stroke, width: circle.strokeWidth, to: &lines)
                }
            default:
                break
            }
        }

        fillSource?.shape = MLNShapeCollectionFeature(shapes: fills)
        lineSource?.shape = MLNShapeCollectionFeature(shapes: lines)
        markerSource?.shape = MLNShapeCollectionFeature(shapes: markers)
    }

    /// The overlays under `point`, topmost first, as (kind, id) pairs.
    ///
    /// Each layer is queried on its own, in drawing order: markers over lines over fills.
    /// One query for all layers returns hits in no fixed order, so a fill could win over a pin.
    func hits(at point: CGPoint) -> [(kind: String, id: String)] {
        guard let map else { return [] }
        return [Name.markerLayer, Name.lineLayer, Name.fillLayer].flatMap { layer in
            map.mlnMapView.visibleFeatures(at: point, styleLayerIdentifiers: [layer]).compactMap { feature in
                guard let kind = feature.attributes["kind"] as? String,
                      let id = feature.attributes["id"] as? String else { return nil }
                return (kind, id)
            }
        }
    }

    /// The identifier an overlay has in the features, and in `hits`.
    static func identifier(for overlay: GMSOverlay) -> String {
        String(ObjectIdentifier(overlay).hashValue)
    }

    // MARK: - Features

    private func markerFeature(_ marker: GMSMarker, id: String, style: MLNStyle) -> MLNShape {
        let name: String
        let image: UIImage
        if let icon = marker.icon {
            name = "siro-icon-\(ObjectIdentifier(icon).hashValue)"
            image = icon
        } else {
            name = Renderer.defaultPinName
            image = Renderer.defaultPin
        }
        if !images.contains(name) {
            style.setImage(image, forName: name)
            images.insert(name)
        }

        let feature = MLNPointFeature()
        feature.coordinate = marker.position
        feature.attributes = [
            "id": id,
            "kind": "marker",
            "icon": name,
            "anchor": anchorName(marker.groundAnchor),
            "rotation": marker.rotation,
            "opacity": Double(marker.opacity),
        ]
        return feature
    }

    private func appendLine(_ coordinates: [CLLocationCoordinate2D], id: String, kind: String, color: UIColor, width: CGFloat, to lines: inout [MLNShape]) {
        guard coordinates.count >= 2 else { return }
        let feature = coordinates.withUnsafeBufferPointer { buffer in
            MLNPolylineFeature(coordinates: buffer.baseAddress!, count: UInt(buffer.count))
        }
        feature.attributes = [
            "id": id,
            "kind": kind,
            "color": cssColor(color),
            "width": Double(width),
        ]
        lines.append(feature)
    }

    private func polygonFeature(outer: [CLLocationCoordinate2D], holes: [[CLLocationCoordinate2D]], id: String, kind: String, fill: UIColor) -> MLNShape? {
        guard outer.count >= 3 else { return nil }
        let interior = holes.map { ring in
            ring.withUnsafeBufferPointer { buffer in
                MLNPolygon(coordinates: buffer.baseAddress!, count: UInt(buffer.count))
            }
        }
        let feature = outer.withUnsafeBufferPointer { buffer in
            MLNPolygonFeature(coordinates: buffer.baseAddress!, count: UInt(buffer.count), interiorPolygons: interior)
        }
        feature.attributes = [
            "id": id,
            "kind": kind,
            "color": cssColor(fill),
        ]
        return feature
    }

    /// Splits a line into pieces, one per span. A solid span is one piece; a gradient is drawn as eight steps.
    /// Spans count path segments, and the last one runs to the end of the line.
    private func styledPieces(of coordinates: [CLLocationCoordinate2D], spans: [GMSStyleSpan]) -> [(coordinates: [CLLocationCoordinate2D], color: UIColor)] {
        let total = Double(coordinates.count - 1)
        guard total > 0 else { return [] }
        var pieces: [(coordinates: [CLLocationCoordinate2D], color: UIColor)] = []
        var position = 0.0
        for (index, span) in spans.enumerated() {
            guard position < total else { break }
            let isLast = index == spans.count - 1
            let end = isLast ? total : min(position + max(span.segments, 0), total)
            guard end > position else { continue }
            if let endColor = span.style.endColor {
                let steps = 8
                for step in 0..<steps {
                    let from = position + (end - position) * Double(step) / Double(steps)
                    let to = position + (end - position) * Double(step + 1) / Double(steps)
                    let color = Renderer.mix(span.style.color, endColor, (Double(step) + 0.5) / Double(steps))
                    pieces.append((slice(coordinates, from: from, to: to), color))
                }
            } else {
                pieces.append((slice(coordinates, from: position, to: end), span.style.color))
            }
            position = end
        }
        return pieces
    }

    /// The part of a line between two fractional segment positions.
    private func slice(_ coordinates: [CLLocationCoordinate2D], from: Double, to: Double) -> [CLLocationCoordinate2D] {
        func point(at position: Double) -> CLLocationCoordinate2D {
            let index = min(Int(position), coordinates.count - 1)
            let fraction = position - Double(index)
            guard fraction > 0, index + 1 < coordinates.count else { return coordinates[index] }
            let a = coordinates[index], b = coordinates[index + 1]
            return CLLocationCoordinate2D(
                latitude: a.latitude + (b.latitude - a.latitude) * fraction,
                longitude: a.longitude + (b.longitude - a.longitude) * fraction
            )
        }
        var out = [point(at: from)]
        var vertex = Int(from.rounded(.down)) + 1
        while Double(vertex) < to {
            out.append(coordinates[vertex])
            vertex += 1
        }
        out.append(point(at: to))
        return out
    }

    private static func mix(_ a: UIColor, _ b: UIColor, _ t: Double) -> UIColor {
        var (r1, g1, b1, a1): (CGFloat, CGFloat, CGFloat, CGFloat) = (0, 0, 0, 0)
        var (r2, g2, b2, a2): (CGFloat, CGFloat, CGFloat, CGFloat) = (0, 0, 0, 0)
        a.getRed(&r1, green: &g1, blue: &b1, alpha: &a1)
        b.getRed(&r2, green: &g2, blue: &b2, alpha: &a2)
        let f = CGFloat(t)
        return UIColor(red: r1 + (r2 - r1) * f, green: g1 + (g2 - g1) * f, blue: b1 + (b2 - b1) * f, alpha: a1 + (a2 - a1) * f)
    }

    /// The symbol anchor closest to a unit-coordinate ground anchor.
    private func anchorName(_ anchor: CGPoint) -> String {
        let vertical: String? = anchor.y >= 0.75 ? "bottom" : (anchor.y <= 0.25 ? "top" : nil)
        let horizontal: String? = anchor.x >= 0.75 ? "right" : (anchor.x <= 0.25 ? "left" : nil)
        switch (vertical, horizontal) {
        case let (v?, h?): return "\(v)-\(h)"
        case let (v?, nil): return v
        case let (nil, h?): return h
        case (nil, nil): return "center"
        }
    }
}
