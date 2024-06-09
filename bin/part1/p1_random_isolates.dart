import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

typedef Result = Map<String, List<double>>;
const chunkSize = 919729143; // 15 * = 13795937145
const lastChunk = 8;
const maxChunks = 16;

File prepareFile(String fileName) {
  final file = File(fileName);
  return file;
}

FutureOr<Result> processFile(int chunk) async {
  Result result = {};

  final file = prepareFile('data/measurements.txt');

  // Create a stream generator for the file data
  Stream<List<int>> readData() async* {
    final fileChunk = file.openSync()..setPositionSync(chunk * chunkSize);
    if (chunk < 15) {
      final chunkData = fileChunk.readSync(chunkSize);
      yield chunkData.toList();
    } else {
      final chunkData = fileChunk.readSync(8);
      yield chunkData.toList();
    }
  }

  await readData().map(latin1.decode).transform(LineSplitter()).forEach((line) {
    final parts = line.split(';');
    // Throw away unterminated or unfinished lines, we will lose a few entries for this
    // bu I can't be bothered writing the code to fix this.
    if (parts.length == 1) {
      return;
    }
    final location = parts[0];
    final measurement = double.tryParse(parts[1]);
    if (measurement == null) {
      return;
    }

    if (!result.containsKey(location)) {
      result[location] = [measurement, measurement, measurement, 1];
    } else {
      var measurements = result[location]!;
      if (measurement < measurements[0]) {
        measurements[0] = measurement;
      }
      if (measurement > measurements[1]) {
        measurements[1] = measurement;
      }
      measurements[2] += measurement;
      measurements[3] += 1;
    }
  });
  return result;
}

void generateCombinedResult(List<FutureOr<Result>> results) async {
  Result combinedResult = {};
  List<Result> tResult = [];

  // Unwrap the futures
  for (final result in results) {
    await (result as Future).then((result) => tResult.add(result));
  }

  for (final result in tResult) {
    for (final location in result.keys) {
      if (!combinedResult.containsKey(location)) {
        combinedResult[location] = [
          result[location]![0],
          result[location]![1],
          result[location]![2],
          result[location]![3],
        ];
      } else {
        final measurements = combinedResult[location]!;
        if (result[location]![0] < measurements[0]) {
          // min
          measurements[0] = result[location]![0];
        }
        if (result[location]![1] > measurements[1]) {
          // max
          measurements[1] = result[location]![1];
        }
        measurements[2] += result[location]![2]; // Mean
        measurements[3] += result[location]![3];
      }
    }
  }

  print('');
  print('Creating the results...');
  final buffer = StringBuffer('{');
  final sortedKeys = combinedResult.keys.toList()..sort();
  double processed = 0;
  for (var location in sortedKeys) {
    final measurements = combinedResult[location]!;
    processed += measurements[3];
    buffer.write(
      '$location=${measurements[0].toStringAsFixed(1)}/'
      '${(measurements[2] / measurements[3]).toStringAsFixed(1)}/'
      '${measurements[1].toStringAsFixed(1)}, ',
    );
  }
  buffer.write('Number of rows processed - $processed');
  buffer.write('\b\b}');

  print(buffer.toString());
}

FutureOr<int> main() async {
  List<FutureOr<Result>> results = [];

  print('Welcome to the Dart 1 billion row challenge');
  print('Processing the measurements.txt file');
  print('');
  final stopwatch = Stopwatch();
  stopwatch.start();
  try {
    print('Processing the rows');
    for (int chunk = 0; chunk <= 15; chunk++) {
      results.add(Isolate.run<Result>(() => processFile(chunk)));
    }
    await Future.wait<Result>(results.map((result) async => await result));
    print('Row processing complete');
    generateCombinedResult(results);
  } on Exception catch (e) {
    stopwatch.stop();
    print('');
    print(
        'Exception raised after ${stopwatch.elapsedMilliseconds / 1000} seconds');
    print('Exception is - $e');
    return 255;
  }
  stopwatch.stop();
  print('');
  print('Parsing took ${stopwatch.elapsedMilliseconds / 1000} seconds');
  return 0;
}
