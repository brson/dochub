#!/bin/sh

# execute with
# wget -qO- https://raw.github.com/brson/dochub/master/bootstrap.sh | sudo -u ubuntu sh

cd && \
sudo apt-get install -y git rubygems1.8 ruby-bundler libxml2-dev libxslt1-dev && \
rm -rf dochub
git clone git://github.com/brson/dochub && \
cd dochub && \
sudo bundle install && \
/var/lib/gems/1.8/bin/rackup &
