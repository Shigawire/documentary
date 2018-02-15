require 'sidekiq'
require 'sidekiq/batches'
require 'logger'

require_relative 'command'
require_relative 'workers'

$stdout.sync = true

class ScanJob
  FILE_FORMAT = ENV.fetch('FILE_FORMAT')

  attr_accessor :tmpdir, :scanfiles

  def self.preprocess_callback(tmpdir)
    self.new(tmpdir).postprocess_scanfiles
  end

  def initialize(tmpdir)
    self.logger = Logger.new(STDOUT)
    self.tmpdir = tmpdir
    self.scanfiles = build_scanfiles
  end

  def perform
    preprocess_scanfiles
    # unless Dir.glob("#{tmpdir}/*.pdf").any?
    #   preprocess_scanfiles
    # else
    #   postprocess_scanfiles
    # end
  end

  def preprocess_scanfiles
    batch = Sidekiq::Batch.new
    batch.on(:success, 'ScanJob#preprocess_callback', tmpdir: tmpdir)
    batch.jobs do
      scanfiles.each do |scanfile|
        Workers::ScanFileWorker.perform_async(scanfile)
      end
    end
  end

  def postprocess_scanfiles
    merge
    upload
    verify
  end

  def merge
    logger.info("Merging all PDFs.")
    cmd = "gs -dDownsampleColorImages=true -dColorImageResolution=150 -sDEVICE=pdfwrite -dPDFA=2 -dBATCH -dNOPAUSE -sProcessColorModel=DeviceRGB -sColorConversionStrategy=/RGB -sPDFACompatibilityPolicy=1 -sOutputFile=#{tmpdir}/postprocessed.pdf #{tmpdir}/*.#{FILE_FORMAT}.pdf"
    Command.(cmd)
  end

  def upload
    logger.info("Uploading finished pdf.")
  end

  def verify
    # download
    # count pages
  end

private
  def build_scanfiles
    filelist = Dir.glob("#{tmpdir}/*.#{FILE_FORMAT}")
    filelist.each { |filepath| ScanFile.new(fullpath: filepath) }
  end
end
