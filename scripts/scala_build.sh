#!/bin/sh

project_name=$1

# make dir where project will reside and navigate to it
mkdir $project_name
pushd $project_name

# make scala needed dirs
mkdir -p src/{main,test}/{java,resources,scala}
mkdir lib project target

# create an initial build.sbt file
echo "name := \"$project_name\"
version := \"1.0\"
scalaVersion := \"2.10.0\"" > build.sbt

popd
