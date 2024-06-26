import 'dart:async';
import 'dart:io';

int rowNum = 0;

FutureOr<void> processFile(String fileName) async {
  var result = <String, List<double>>{};

  var file = File(fileName);
  var lines = await file.readAsLines();
  print('processFile: Finished reading the file as lines(rows)');

  print('Processing the rows....');
  for (var line in lines) {
    rowNum++;
    var parts = line.split(';');
    var location = parts[0];
    var measurement = double.parse(parts[1]);

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
  }

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

FutureOr<void> main() async {
  print('Welcome to the Dart 1 billion row challenge');
  print('Processing the measurements.txt file');
  final stopwatch = Stopwatch();
  stopwatch.start();
  try {
    await processFile('data/measurements.txt');
  } on Exception {
    stopwatch.stop();
    print(
        'Exception raised after ${stopwatch.elapsedMilliseconds / 1000} seconds, processed $rowNum rows');
  }
  stopwatch.stop();
  print(
      'Parsing took ${stopwatch.elapsedMilliseconds / 1000} seconds, processed $rowNum rows');
}
