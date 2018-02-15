#!/usr/bin/env ruby
require 'tmpdir'
require 'logger'
require 'fileutils'
require 'rubygems'
require 'bundler/setup'
require 'sidekiq'
require 'sidekiq/batch'
require 'active_support/inflector' # sidekiq/batch uses constantize

require_relative 'lib/scan_file'
require_relative 'lib/scan_job'
require_relative 'lib/scanner'
require_relative 'lib/workers'

$stdout.sync = true

Scanner.new(from_directory: ARGV[0]).perform
