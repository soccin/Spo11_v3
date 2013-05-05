#!/bin/bash

awk '$10=="AS.orig" || $11/$10>.85{print $0}'

