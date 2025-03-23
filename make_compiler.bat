@echo off
docker run --rm -v %cd%/out:/workspace -e TARGET=%1 -it gagameosgeneratecompiler