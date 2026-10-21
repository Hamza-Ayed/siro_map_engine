import Flutter
import Foundation
import MapLibre
import UIKit

public class SiroGlPlugin: NSObject, FlutterPlugin {
    static var downloadOfflineRegionChannelHandler: OfflineChannelHandler? = nil


    public static func register(with registrar: FlutterPluginRegistrar) {
        let instance = SiroMapFactory(withRegistrar: registrar)
        registrar.register(instance, withId: "com.siro.gl/map")

        // Register the header-injection protocol before any MLNMapView is created.
        // MLNNetworkConfiguration docs require sessionConfiguration to be set before
        // the first map view; we bake the protocol class into the session config here
        // so that SiroHeadersProtocol can intercept requests at call time.
        let sessionConfig = MLNNetworkConfiguration.sharedManager.sessionConfiguration
            ?? URLSessionConfiguration.default
        sessionConfig.protocolClasses = [SiroHeadersProtocol.self]
            + (sessionConfig.protocolClasses ?? [])
        MLNNetworkConfiguration.sharedManager.sessionConfiguration = sessionConfig

        let channel = FlutterMethodChannel(
            name: "com.siro.gl/global",
            binaryMessenger: registrar.messenger()
        )

        channel.setMethodCallHandler { methodCall, result in
            switch methodCall.method {
            case "setHttpHeaders":
                guard let arguments = methodCall.arguments as? [String: Any],
                      let headers = arguments["headers"] as? [String: String]
                else {
                    result(FlutterError(
                        code: "setHttpHeadersError",
                        message: "could not decode arguments",
                        details: nil
                    ))
                    return
                }
                SiroCustomHeaders.setHeaders(headers)
                result(nil)
            case "setOffline":
                // MapLibre iOS has no forced-offline switch. See SiroForcedOffline.
                guard let arguments = methodCall.arguments as? [String: Any],
                      let offline = arguments["offline"] as? Bool
                else {
                    result(FlutterError(
                        code: "setOfflineError",
                        message: "could not decode arguments",
                        details: nil
                    ))
                    return
                }
                SiroForcedOffline.setEnabled(offline)
                result(nil)
            case "updateOfflineRegionMetadata":
                result(FlutterError(
                    code: "UNSUPPORTED",
                    message: "MapLibre iOS cannot change an offline region's metadata in place. Delete the region and download it again with the new metadata.",
                    details: nil
                ))
            case "setNetworkStatsEnabled":
                guard let arguments = methodCall.arguments as? [String: Any],
                      let enabled = arguments["enabled"] as? Bool
                else {
                    result(FlutterError(
                        code: "setNetworkStatsEnabledError",
                        message: "could not decode arguments",
                        details: nil
                    ))
                    return
                }
                SiroNetworkStats.setEnabled(enabled)
                result(nil)
            case "getNetworkStats":
                // Bytes are null on iOS: see SiroNetworkStats.
                result([
                    "requests": SiroNetworkStats.snapshot(),
                    "bytes": NSNull(),
                ])
            case "resetNetworkStats":
                SiroNetworkStats.reset()
                result(nil)
            case "installOfflineMapTiles":
                guard let arguments = methodCall.arguments as? [String: String] else { return }
                let tilesdb = arguments["tilesdb"]
                installOfflineMapTiles(registrar: registrar, tilesdb: tilesdb!)
                result(nil)
            case "downloadOfflineRegion#setup":
                guard let args = methodCall.arguments as? [String: Any],
                      let channelName = args["channelName"] as? String
                else {
                    print(
                        "downloadOfflineRegion#setup unexpected arguments: \(String(describing: methodCall.arguments))"
                    )
                    result(nil)
                    return
                }

                downloadOfflineRegionChannelHandler = OfflineChannelHandler(
                    messenger: registrar.messenger(),
                    channelName: channelName
                )

                result(nil)
            case "downloadOfflineRegion":
                // Get download region arguments from caller
                guard let args = methodCall.arguments as? [String: Any],
                      let definitionDictionary = args["definition"] as? [String: Any],
                      let metadata = args["metadata"] as? [String: Any],
                      let defintion = OfflineRegionDefinition.fromDictionary(definitionDictionary)
                else {
                    print(
                        "downloadOfflineRegion unexpected arguments: \(String(describing: methodCall.arguments))"
                    )
                    result(nil)
                    return
                }

                if (downloadOfflineRegionChannelHandler == nil) {
                    result(FlutterError(
                        code: "downloadOfflineRegion#setup NOT CALLED",
                        message: "The setup has not been called, please call downloadOfflineRegion#setup before",
                        details: nil
                    ))
                    return
                }

                OfflineManagerUtils.downloadRegion(
                    definition: defintion,
                    metadata: metadata,
                    result: result,
                    registrar: registrar,
                    channelHandler: downloadOfflineRegionChannelHandler!
                )
                downloadOfflineRegionChannelHandler = nil;
            case "setOfflineTileCountLimit":
                guard let arguments = methodCall.arguments as? [String: Any],
                      let limit = arguments["limit"] as? UInt64
                else {
                    result(FlutterError(
                        code: "SetOfflineTileCountLimitError",
                        message: "could not decode arguments",
                        details: nil
                    ))
                    return
                }
                OfflineManagerUtils.setOfflineTileCountLimit(result: result, maximumCount: limit)
            case "getListOfRegions":
                // Note: this does not download anything from internet, it only fetches data drom database
                OfflineManagerUtils.regionsList(result: result)
            case "mergeOfflineRegions":
                guard let args = methodCall.arguments as? [String: Any],
                      let path = args["path"] as? String
                else {
                    result(FlutterError(
                        code: "INVALID_ARGUMENT",
                        message: "Expected a 'path' string argument",
                        details: nil
                    ))
                    return
                }
                OfflineManagerUtils.mergeRegions(result: result, path: path)
            case "getOfflineDatabasePath":
                // The shared store backing offline packs and the ambient cache.
                // This is the same file mergeOfflineRegions imports from.
                result(MLNOfflineStorage.shared.databaseURL.path)
            case "deleteOfflineRegion":
                guard let args = methodCall.arguments as? [String: Any],
                      let id = args["id"] as? Int
                else {
                    result(nil)
                    return
                }
                OfflineManagerUtils.deleteRegion(result: result, id: id)
            case "clearAmbientCache":
                OfflineManagerUtils.clearAmbientCache(result: result)
            case "resetOfflineDatabase":
                OfflineManagerUtils.resetOfflineDatabase(result: result)
            case "pauseOfflineRegionDownload":
                guard let args = methodCall.arguments as? [String: Any],
                      let id = args["id"] as? Int
                else {
                    result(nil)
                    return
                }
                OfflineManagerUtils.pauseRegion(result: result, id: id)
            case "resumeOfflineRegionDownload":
                guard let args = methodCall.arguments as? [String: Any],
                      let id = args["id"] as? Int
                else {
                    result(nil)
                    return
                }
                OfflineManagerUtils.resumeRegion(result: result, id: id)
            case "getOfflineRegionStatus":
                guard let args = methodCall.arguments as? [String: Any],
                      let id = args["id"] as? Int
                else {
                    result(nil)
                    return
                }
                OfflineManagerUtils.getRegionStatus(result: result, id: id)
            case "setOfflineMaxConcurrentRequests":
                let args = methodCall.arguments as? [String: Any]
                let maxRequestsPerHost = args?["maxRequestsPerHost"] as? Int
                OfflineManagerUtils.setMaxConcurrentRequests(
                    result: result,
                    maxRequestsPerHost: maxRequestsPerHost
                )
            case "preWarm":
                _ = MLNOfflineStorage.shared
                result(nil)
            default:
                result(FlutterMethodNotImplemented)
            }
        }
    }

    private static func getTilesUrl() -> URL {
        guard var cachesUrl = FileManager.default.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        ).first,
            let bundleId = Bundle.main
            .object(forInfoDictionaryKey: kCFBundleIdentifierKey as String) as? String
        else {
            fatalError("Could not get map tiles directory")
        }
        cachesUrl.appendPathComponent(bundleId)
        cachesUrl.appendPathComponent(".mapbox")
        cachesUrl.appendPathComponent("cache.db")
        return cachesUrl
    }

    // Copies the "offline" tiles to where MapLibre expects them
    private static func installOfflineMapTiles(registrar: FlutterPluginRegistrar, tilesdb: String) {
        var tilesUrl = getTilesUrl()
        let bundlePath = getTilesDbPath(registrar: registrar, tilesdb: tilesdb)
        NSLog(
            "Cached tiles not found, copying from bundle... \(String(describing: bundlePath)) ==> \(tilesUrl)"
        )
        do {
            let parentDir = tilesUrl.deletingLastPathComponent()
            try FileManager.default.createDirectory(
                at: parentDir,
                withIntermediateDirectories: true,
                attributes: nil
            )
            if FileManager.default.fileExists(atPath: tilesUrl.path) {
                try FileManager.default.removeItem(atPath: tilesUrl.path)
            }
            try FileManager.default.copyItem(atPath: bundlePath!, toPath: tilesUrl.path)
            var resourceValues = URLResourceValues()
            resourceValues.isExcludedFromBackup = true
            try tilesUrl.setResourceValues(resourceValues)
        } catch {
            NSLog("Error copying bundled tiles: \(error)")
        }
    }

    private static func getTilesDbPath(registrar: FlutterPluginRegistrar,
                                       tilesdb: String) -> String?
    {
        if tilesdb.starts(with: "/") {
            return tilesdb
        } else {
            let key = registrar.lookupKey(forAsset: tilesdb)
            return Bundle.main.path(forResource: key, ofType: nil)
        }
    }
}
