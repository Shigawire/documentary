#!/usr/bin/env ruby
require 'tmpdir'
require 'logger'
require 'fileutils'
require 'thread/pool'
require 'google_drive'

$stdout.sync = true

FILE_FORMAT = 'tiff'
FILE_FORMATTING = "%03d.#{FILE_FORMAT}"
DEFAULT_RESOLUTION = 300
MAX_THREADS = 4
GDRIVE_FOLDER_ID = '1Q1vXHp5XwPw7Z9NYYKEi8Q4Ir_iCtbp5'

class Scanner
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
    upload_to_google

    #5. cleanup after ourselves
    cleanup

    logger.info('Done.')
  end

  def ocr
    pool = Thread.pool(MAX_THREADS)
    logger.info("About to OCR all files.")
    Dir.glob("#{tmpdir}/*.#{FILE_FORMAT}").each do |filename|
      pool.process do
        cmd = "tesseract -l deu+eng #{filename} #{filename} pdf"
        call(cmd)
      end
    end
    pool.shutdown

    raise 'Tesseract failed.' unless verify_tesseract
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
    call(cmd)
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
    cmd = "scanimage -d canon_dr --batch=\"#{scans_path}\" --source \"ADF Duplex\" --resolution #{resolution} --mode Gray --format #{FILE_FORMAT}"
    call(cmd)
  end

  def call(cmd)
    logger.info("Calling #{cmd}")
    `#{cmd}`.tap do
      if (status = $?.exitstatus) != 0
        raise "#{cmd} exited with status #{status}"
      end
    end
  end
end

Scanner.new.perform
