#!/bin/bash
\curl -L https://get.rvm.io | bash -s stable --rails --autolibs=enabled # Or, --ruby=1.9.3
cd src
make
cd ..

