#!/bin/sh
make -j4 > log
make -j4 OPENMW_PATH=/mnt/c/Users/Chris/Documents/OpenMW/openmw_head  TARGET_NAME=target_head > log_head
