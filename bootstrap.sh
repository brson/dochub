#!/bin/sh

# execute with
# wget -qO- https://raw.github.com/brson/dochub/master/bootstrap.sh | sudo -u ubuntu sh

cd && \
sudo apt-get install -y git rubygems1.8 ruby-bundler libxml2-dev libxslt1-dev && \
git clone git://github.com/brson/dochub && \
cd dochub && \
sudo bundle install && \
rackup &
