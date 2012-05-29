#!/bin/sh

cd && \
sudo apt-get install git rubygems1.8 ruby-bundler libxml2-dev libxslt1-dev && \
git clone git://github.com/brson/dochub && \
cd dochub && \
sudo bundler install && \
rackup &
