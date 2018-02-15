require 'tmpdir'
require 'logger'
require 'fileutils'
require 'rubygems'
require 'bundler/setup'
require 'sidekiq'
require 'sidekiq/batch'
require 'active_support/inflector' # sidekiq/batch uses constantize
require 'google_drive'

require_relative 'lib/command'
require_relative 'lib/scanner'
require_relative 'lib/workers'
require_relative 'lib/workflows'
