#!/usr/bin/env ruby
require 'tmpdir'
require 'logger'
require 'fileutils'
require 'pathname'
require 'sidekiq'

require_relative 'lib/directory'
require_relative 'lib/scanner'
require_relative 'lib/command'
require_relative 'lib/workers'

directory = if ARGV[0]
              Directory.new(path: Pathname.new(File.expand_path(File.join(Dir.pwd, ARGV[0]))))
            else
              Directory.new(path: Pathname.new(Dir.mktmpdir), to_be_removed: true).tap do |dir|
                Scanner.new(directory: dir).perform
              end
            end
Workers::JobWorker.perform_async(directory: directory.to_h)
