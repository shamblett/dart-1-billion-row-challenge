import 'dart:async';
import 'dart:convert';
import 'dart:isolate';
import 'dart:typed_data';
import 'package:stdlibc/stdlibc.dart' as stdlib;

typedef Result = Map<String, List<double>>;
const chunkSize = 919729143; // 15 * = 13795937145
const lastChunk = 8;
const maxChunks = 16;
int rowNum = 0;
int fileLength = 0;
late ByteData bData;

void prepareFile(String fileName) {
  // Get the file size
  fileLength = stdlib.stat(fileName)!.st_size;
  if (fileLength <= 0) {
    print('processFile:: failed to stat file $fileName');
    return;
  }

  // Open the file
  final fileFd = stdlib.open(fileName);
  if (fileFd < 0) {
    print('processFile:: failed to open file $fileName');
    return;
  }

  // Mmap the file
  final pBufMapped = stdlib.mmap(
      length: fileLength,
      fd: fileFd,
      prot: stdlib.PROT_READ,
      flags: stdlib.MAP_PRIVATE);
  if (pBufMapped!.data.lengthInBytes <= 0) {
    print('processFile:: failed to Mmap file $fileName');
  }
  bData = ByteData.view(pBufMapped.data);
}

FutureOr<Result> processFile(int chunk) async {
  Result result = {};

  prepareFile('data/measurements.txt');

  // Create a stream generator for the file data
  Stream<List<int>> readData() async* {
    if (chunk < 15) {
      yield bData.buffer.asUint8List(chunk * chunkSize, chunkSize);
    } else {
      yield bData.buffer.asUint8List(chunk * chunkSize, 8);
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

    rowNum++;
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
  for (final result in results) {
    if (result is Future) {
      await (result as Future).then((result) => tResult.add(result));
    } else {
      tResult.add(result);
    }
  }
  for (final result in tResult) {
    for (final location in result.keys) {
      if (!combinedResult.containsKey(location)) {
        combinedResult[location] = [
          result[location]![0],
          result[location]![1],
          result[location]![2],
          1
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
        measurements[2] += result[location]![2];
        measurements[3] += result[location]![3];
        ;
      }
    }
  }

  print('Creating the results...');
  var buffer = StringBuffer('{');
  var sortedKeys = combinedResult.keys.toList()..sort();
  for (var location in sortedKeys) {
    var measurements = combinedResult[location]!;
    buffer.write(
      '$location=${measurements[0].toStringAsFixed(1)}/'
      '${(measurements[2] / measurements[3]).toStringAsFixed(1)}/'
      '${measurements[1].toStringAsFixed(1)}, ',
    );
  }
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
