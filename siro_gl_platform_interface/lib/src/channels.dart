part of '../siro_gl_platform_interface.dart';

/// Method channel for calls that are not tied to one map.
///
/// Android and iOS register the same strings. Change them here and in the
/// native plugins together, or calls will not reach the plugin.
const String siroGlobalChannelName = 'com.siro.gl/global';

/// Prefix of the per-map method channel. Each map appends its view id.
const String siroMapChannelPrefix = 'com.siro.gl/map_';

/// Platform view type that hosts one map on Android and iOS.
const String siroMapViewType = 'com.siro.gl/map';
