// Compiled to web/drift_worker.js at build time — see the "Compile the
// drift web worker" step in README/CI. Runs the sqlite3 wasm database in a
// dedicated/shared worker so drift's web backend can use it.
import 'package:drift/wasm.dart';

void main() {
  WasmDatabase.workerMainForOpen();
}
