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
better-suited file handling/processing functionality, i.e. using large file handling and isolatesI(part 2).

The following results should be measured against the average timing(3 runs) for the python script calc_python_base_py
which on the test machine was approx 472 seconds. Note that the test machine is a 20 × Core™ i9-10900T with 64Gb of Ram and 
SSD storage running stock Fedora 40. You will need more than 32G of RAM to run the tests marked * below.

The Medium article accompanying this project can be found [here](https://medium.com/@stevehamblett/dart-one-billion-row-challenge-4993b71e82c0?sk=5cdc7d455673494f8b7c4e0ac65b753d)

# Results

All timings are averaged over 3 runs in seconds.

calc_python_base.py  472 seconds

## Part 1

| Name               | Time(s) |
|:-------------------|:-------:|
| p1_base_naive      |   N/A   |
| p1_base            |   307   |
| p1_random_isolates |   N/A   | 


## Part 2

|       Name        | Time(s) |
|:-----------------:|:-------:|
|   * p2_lfh_base   |   291   |
| * p2_lfh_isolates |   64    |

https://medium.com/@stevehamblett/dart-one-billion-row-challenge-4993b71e82c0?sk=5cdc7d455673494f8b7c4e0ac65b753d