import Foundation

/// The kind of base map, as Google's `GMSMapViewType`.
public enum GMSMapViewType: UInt {
    case none = 0
    case normal = 1
    case satellite = 2
    case terrain = 3
    case hybrid = 4
}

/// Siro's own styles on our server. Not part of Google's API.
public enum SiroStyleURL {
    public static let day = URL(string: "https://map-saas.intaleqapp.com/siro/style-sovereign.json")!
    public static let night = URL(string: "https://map-saas.intaleqapp.com/siro/style-sovereign-night.json")!
    /// The 3D style with terrain, the one `.terrain` uses.
    public static let tactical = URL(string: "https://map-saas.intaleqapp.com/siro/style-sovereign-tactical.json")!
}

/// A style for the map, as Google's `GMSMapStyle`. Either a JSON style or one of Siro's style URLs.
public final class GMSMapStyle: NSObject {

    internal let json: String?
    internal let url: URL?

    /// Creates a style from a JSON string. Throws if it is not a JSON object.
    public init(jsonString: String) throws {
        guard let data = jsonString.data(using: .utf8) else {
            throw GMSMapStyle.invalidStyleError()
        }
        try GMSMapStyle.validate(data)
        json = jsonString
        url = nil
        super.init()
    }

    /// Creates a style from a JSON file. Throws if the file is not a JSON object.
    public init(contentsOfFileURL fileURL: URL) throws {
        let data = try Data(contentsOf: fileURL)
        try GMSMapStyle.validate(data)
        json = String(data: data, encoding: .utf8)
        url = nil
        super.init()
    }

    /// One of Siro's styles on our server, such as `SiroStyleURL.night`.
    public init(siroStyleURL styleURL: URL) {
        json = nil
        url = styleURL
        super.init()
    }

    public class func style(withJSONString jsonString: String) throws -> GMSMapStyle {
        try GMSMapStyle(jsonString: jsonString)
    }

    private static func validate(_ data: Data) throws {
        guard (try? JSONSerialization.jsonObject(with: data)) is [String: Any] else {
            throw invalidStyleError()
        }
    }

    private static func invalidStyleError() -> NSError {
        NSError(
            domain: "com.siro.maps",
            code: 1,
            userInfo: [NSLocalizedDescriptionKey: "The map style is not a valid JSON object."]
        )
    }
}
