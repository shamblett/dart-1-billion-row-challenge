import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:stdlibc/stdlibc.dart' as stdlib;
import '../part1/base_results_map.dart';

int rowNum = 0;

FutureOr<void> processFile(String fileName) async {
  // Get the file size
  final fileLength = stdlib.stat(fileName)!.st_size;
  if (fileLength <= 0) {
    print('processFile:: failed to stat file $fileName');
    return;
  }

  print('The file length is $fileLength');
  print('');

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

  final bData = ByteData.view(pBufMapped.data);

  // Create a stream generator for the file data
  Stream<List<int>> readData() async* {
    yield bData.buffer.asUint8List(0, fileLength);
  }

  print('Processing the rows....');
  await readData().map(latin1.decode).transform(LineSplitter()).forEach((line) {
    final parts = line.split(';');
    final location = parts[0];
    final measurement = double.parse(parts[1]);

    rowNum++;
    final measurements = result[location]!;
    if (measurement < measurements[0]) {
      measurements[0] = measurement;
    }
    if (measurement > measurements[1]) {
      measurements[1] = measurement;
    }
    measurements[2] += measurement;
    measurements[3] += 1;
  });

  print('Creating the results...');
  var buffer = StringBuffer('{');
  var sortedKeys = result.keys.toList()..sort();
  for (var location in sortedKeys) {
    var measurements = result[location]!;
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
  print('Welcome to the Dart 1 billion row challenge');
  print('Processing the measurements.txt file');
  print('');
  final stopwatch = Stopwatch();
  stopwatch.start();
  try {
    await processFile('data/measurements.txt');
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
