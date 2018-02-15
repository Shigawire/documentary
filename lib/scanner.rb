require_relative 'command'
require_relative 'workers'
require_relative 'scan_job'

class Scanner
  FILE_FORMAT = ENV.fetch('FILE_FORMAT', 'tiff')
  FILE_FORMATTING = "%03d.#{FILE_FORMAT}"
  DEFAULT_RESOLUTION = 300
  SANE_DEVICE_NAME = ENV.fetch('SANE_DEVICE_NAME')
  SANE_SOURCE_NAME = ENV.fetch('SANE_SOURCE_NAME', 'ADF Duplex')

  attr_accessor :tmpdir, :resolution, :logger, :scanjob

  def initialize
    self.logger = Logger.new(STDOUT)
    logger.info "Creating tempdir"
    self.tmpdir = Dir.mktmpdir
    self.resolution = DEFAULT_RESOLUTION
  end

  def perform
    scan
    Workers::ScanJobWorker.perform_async(tmpdir)
  end

  def scans_path
    "#{tmpdir}/#{FILE_FORMATTING}"
  end

  def scan
    cmd = "scanimage -d \"#{SANE_DEVICE_NAME}\" --batch=\"#{scans_path}\" --source \"#{SANE_SOURCE_NAME}\" --resolution #{resolution} --mode Gray --format #{FILE_FORMAT}"
    Command.(cmd)
  end
end
