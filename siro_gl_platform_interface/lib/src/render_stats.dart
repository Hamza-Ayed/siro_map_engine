part of '../siro_gl_platform_interface.dart';

/// The frames the map engine finished drawing between `startRenderStats` and
/// `stopRenderStats`.
///
/// These are the map's own frames. Flutter's frame timings do not show them,
/// because the map draws natively on its own thread.
@immutable
class RenderStats {
  const RenderStats({required this.frames, required this.elapsedMs});

  /// Builds the stats from the map returned by the platform.
  factory RenderStats.fromJson(Map<dynamic, dynamic> json) {
    return RenderStats(
      frames: (json['frames'] as num).toInt(),
      elapsedMs: (json['elapsedMs'] as num).toDouble(),
    );
  }

  /// How many frames the engine drew in the window.
  final int frames;

  /// The length of the window, in milliseconds.
  final double elapsedMs;

  /// Frames per second over the window, or 0 for an empty window.
  double get fps => elapsedMs <= 0 ? 0 : frames * 1000 / elapsedMs;

  @override
  bool operator ==(Object other) =>
      other is RenderStats &&
      other.frames == frames &&
      other.elapsedMs == elapsedMs;

  @override
  int get hashCode => Object.hash(frames, elapsedMs);

  @override
  String toString() =>
      'RenderStats(frames: $frames, elapsedMs: ${elapsedMs.toStringAsFixed(0)}, '
      'fps: ${fps.toStringAsFixed(1)})';
}
