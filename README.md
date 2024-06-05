# dart-1-billion-row-challenge
The 1 billion  row challenge for Dart.

Inspired by [this](https://medium.com/towards-data-science/python-one-billion-row-challenge-from-10-minutes-to-4-seconds-0718662b303e) Medium article. 

What is the 1 Billion Row Challenge?

The idea behind the 1 Billion Row Challenge (1BRC) is simple — go through a .txt file that contains arbitrary temperature measurements and calculate summary statistics for each station (min, mean, and max). The only issues are that you’re working with 1 billion rows and that the data is stored in an uncompressed .txt format (13.8 GB).

Please refer to the Python project from above [here](https://github.com/shamblett/dart-1-billion-row-challenge) for instructions on how to generate the measurements.txt file,
the createMeasurements.py file can be found in the data directory for convenience.

The fundamental rule of the challenge is that no external libraries are allowed, which for Dart I'm taking as meaning no 'pub' packages 'dart' packages are allowed as they are
essentially built into Dart.


The goal is to start by obeying the rules(part 1), and then see what happens if you use external libraries and 
better-suited file handling/processing functionality, i.e. using FFI(part 2).

The following results should be measured against the average timing(3 runs) for the python script calc_python_base_py
which on the test machine was approx 500 seconds.

# Results

All timings are averaged over 3 runs in seconds.

## Part 1

|     Name      |  VM   |   Compiled   |
|:-------------:|:-----:|:------------:|
|  base_naive   |  N/A  |     N/A      |
|  base_better  |  348  |     346      |
|   base_best   |  317  |     319      |
