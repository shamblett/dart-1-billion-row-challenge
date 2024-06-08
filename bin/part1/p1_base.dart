import 'dart:async';
import 'dart:io';
import 'dart:convert';

int rowNum = 0;

FutureOr<void> processFile(String fileName) async {
  var result = <String, List<double>>{};

  final file = File(fileName);

  print('Processing the rows....');
  await file
      .openRead()
      .map(latin1.decode)
      .transform(LineSplitter())
      .forEach((line) {
    var parts = line.split(';');
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
