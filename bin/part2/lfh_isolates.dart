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

ByteData prepareFile(String fileName) {
  // Get the file size
  fileLength = stdlib.stat(fileName)!.st_size;
  if (fileLength <= 0) {
    print('processFile:: failed to stat file $fileName');
    return ByteData(0);
  }

  print('The file length is $fileLength');
  print('');

  // Open the file
  final fileFd = stdlib.open(fileName);
  if (fileFd < 0) {
    print('processFile:: failed to open file $fileName');
    return ByteData(0);
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
  return ByteData.view(pBufMapped.data);
}

FutureOr<Result> processFile(int chunk) async {
  Result result = {};

  // Create a stream generator for the file data
  Stream<List<int>> readData() async* {
    if (chunk < 15) {
      yield bData.buffer.asUint8List(chunk * chunkSize, chunkSize);
    } else {
      yield bData.buffer.asUint8List(chunk * chunkSize, 8);
    }
  }

  print('Processing the rows, chunk = $chunk');
  await readData().map(latin1.decode).transform(LineSplitter()).forEach((line) {
    var parts = line.split(';');
    if ( parts.length == 1) {
      return;
    }
    var location = parts[0];
    var measurement = double.parse(parts[1]);

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

FutureOr<int> main() async {
  final results = <FutureOr<Result>>[];

  print('Welcome to the Dart 1 billion row challenge');
  print('Processing the measurements.txt file');
  print('');
  final stopwatch = Stopwatch();
  stopwatch.start();
  try {
    bData = prepareFile('data/measurements.txt');
    for (int chunk = 0; chunk <= 15; chunk++) {
      results.add(Isolate.run(() => processFile(chunk)));
    }
  } on Exception {
    stopwatch.stop();
    print('');
    print(
        'Exception raised after ${stopwatch.elapsedMilliseconds / 1000} seconds, processed $rowNum rows');
    return 255;
  }
  stopwatch.stop();
  print('');
  print(
      'Parsing took ${stopwatch.elapsedMilliseconds / 1000} seconds, processed $rowNum rows');
  return 0;
}
