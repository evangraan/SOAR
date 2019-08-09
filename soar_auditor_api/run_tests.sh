#! /bin/bash

rvm use .
gem install bundler
bundle
bundle exec rspec -cfd spec
