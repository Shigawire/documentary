#!/usr/bin/env ruby
require_relative 'boot'

Scanner.new(from_directory: ARGV[0]).perform
