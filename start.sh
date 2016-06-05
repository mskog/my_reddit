#!/bin/bash

bundle install

bundle exec rackup -s Puma -p 8080 --host 0.0.0.0
