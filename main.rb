#!/usr/bin/env ruby
require 'tmpdir'
require 'logger'
require 'fileutils'
require 'thread/pool'
require 'rubygems'
require 'bundler/setup'

require_relative 'lib/scanner'

$stdout.sync = true

Scanner.new.perform
