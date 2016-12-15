#!/bin/sh
mkdir -p src/{main,test}/{java,resources,scala}
mkdir lib project target

# create an initial build.sbt file
project_name=$1
echo "name := \"$1\"
version := \"1.0\"
scalaVersion := \"2.10.0\"" > build.sbt
