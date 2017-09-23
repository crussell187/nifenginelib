#!/bin/sh
export LD_LIBRARY_PATH=/mnt/c/Users/Chris/Documents/OpenMW/boost_1_61_0/stage/lib
#valgrind --tool=callgrind ./target/benchmark --benchmark_repetitions=40
./target/benchmark --benchmark_repetitions=40
./target_head/benchmark --benchmark_repetitions=40
