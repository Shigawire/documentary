require 'google_drive'
require_relative 'command'
require_relative 'workers'

class Scanner
  FILE_FORMAT = 'tiff'
  FILE_FORMATTING = "%03d.#{FILE_FORMAT}"
  DEFAULT_RESOLUTION = 300
  MAX_THREADS = 4
  SANE_DEVICE_NAME = ENV.fetch('SANE_DEVICE_NAME')
  SANE_SOURCE_NAME = ENV.fetch('SANE_SOURCE_NAME', 'ADF Duplex')
  GDRIVE_FOLDER_ID = ENV.fetch('GDRIVE_FOLDER_ID', nil)

  attr_accessor :tmpdir, :resolution, :logger

  def initialize
    self.logger = Logger.new(STDOUT)
    logger.info "Creating tempdir"
    self.tmpdir = Dir.mktmpdir
    self.resolution = DEFAULT_RESOLUTION
  end

  def perform
    #1. scan
    scan

    #2. ocr
    ocr

    #3. postprocess and merge
    postprocess

    #4. upload
    upload_to_google if GDRIVE_FOLDER_ID

    #5. cleanup after ourselves
    cleanup

    logger.info('Done.')
  end

  def ocr
    logger.info("About to OCR all files.")
    Dir.glob("#{tmpdir}/*.#{FILE_FORMAT}").each do |path|
      Workers::OCRWorker.perform_async(path)
    end

    begin
      retries = 0
      raise 'Tesseract is not finished' unless verify_tesseract
    rescue
      sleep 1
      retry if (retries += 1) < 120
      raise 'Tesseract failed'
    end
  end

  def upload_to_google
    logger.info('Uploading to GDrive')
    session = GoogleDrive::Session.from_config('config.json')
    session.upload_from_file("#{tmpdir}/postprocessed.pdf", safe_filename, { parents: [GDRIVE_FOLDER_ID], convert: false })
  end

  def verify_tesseract
    Dir.glob("#{tmpdir}/*.#{FILE_FORMAT}").count == Dir.glob("#{tmpdir}/*.#{FILE_FORMAT}.pdf").count
  end

  def postprocess
    logger.info("Merging all PDFs.")
    cmd = "gs -dDownsampleColorImages=true -dColorImageResolution=150 -sDEVICE=pdfwrite -dPDFA=2 -dBATCH -dNOPAUSE -sProcessColorModel=DeviceRGB -sColorConversionStrategy=/RGB -sPDFACompatibilityPolicy=1 -sOutputFile=#{tmpdir}/postprocessed.pdf #{tmpdir}/*.tiff.pdf"
    logger.info("Calling #{cmd}")
    Command.(cmd)
  end

  def scans_path
    "#{tmpdir}/#{FILE_FORMATTING}"
  end

  def cleanup
    FileUtils.rm_rf(tmpdir)
  end

  def safe_filename
    Time.now.strftime("%Y-%m-%d - %H_%M_%S.pdf")
  end

  def scan
    cmd = "scanimage -d \"#{SANE_DEVICE_NAME}\" --batch=\"#{scans_path}\" --source \"#{SANE_SOURCE_NAME}\" --resolution #{resolution} --mode Gray --format #{FILE_FORMAT}"
    logger.info("Calling #{cmd}")
    Command.(cmd)
  end
end
