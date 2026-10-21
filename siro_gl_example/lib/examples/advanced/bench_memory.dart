// Resident memory of this process in bytes, or null where it is not available.
//
// Native platforms read `ProcessInfo.currentRss`. Web has no process to ask,
// so the stub returns null.
export 'bench_memory_stub.dart' if (dart.library.io) 'bench_memory_native.dart';
