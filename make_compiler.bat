@echo off
docker run --rm -v %cd%/out:/workspace -e TARGET=%1 -it gagameosgeneratecompiler

if not exist out\compilers mkdir out\compilers
tar -xzvf out/win-%1-gcc.tar.gz -C out/compilers
