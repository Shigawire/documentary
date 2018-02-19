class Scanner
  FILE_FORMAT = ENV.fetch('FILE_FORMAT', 'tiff')
  FILE_FORMATTING = "%03d.#{FILE_FORMAT}"
  DEFAULT_RESOLUTION = 300
  SANE_DEVICE_NAME = ENV.fetch('SANE_DEVICE_NAME', 'canon_dr')
  SANE_SOURCE_NAME = ENV.fetch('SANE_SOURCE_NAME', 'ADF Duplex')

  attr_accessor :directory, :logger

  def initialize(directory:)
    self.logger = Logger.new(STDOUT)
    self.directory = directory
  end

  def perform
    cmd = "scanimage -d \"#{SANE_DEVICE_NAME}\" -l 0 -y 0 -x 210 -y 297 --page-width 210 --page-height 297 --rollerdeskew=yes --contrast 127 --batch=\"#{scans_path}\" --source \"#{SANE_SOURCE_NAME}\" --resolution #{DEFAULT_RESOLUTION} --mode Gray --format #{FILE_FORMAT}"
    Command.(cmd)
  end

  def scans_path
    directory.path.join(FILE_FORMATTING)
  end
end
