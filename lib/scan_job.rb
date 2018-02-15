require 'sidekiq'
require 'sidekiq/batch'
require 'logger'

require_relative 'command'
require_relative 'workers'

class ScanJob
  FILE_FORMAT = ENV.fetch('FILE_FORMAT', 'tiff')

  attr_accessor :tmpdir, :files_to_process, :logger

  def initialize(tmpdir)
    self.logger = Logger.new(STDOUT)
    self.tmpdir = tmpdir
    self.files_to_process = Dir.glob("#{tmpdir}/*.#{FILE_FORMAT}")
  end

  def perform
    batch = Sidekiq::Batch.new
    batch.on(:success, Postprocessor, tmpdir)
    batch.jobs do
      files_to_process.each do |path|
        Workers::ScanFileWorker.perform_async(path)
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

  class Postprocessor
    def on_success(_status, options)
      ScanJob.new(options).postprocess_scanfiles
    end
  end
end
