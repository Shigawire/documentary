module Workflows
  class Job
    FILE_FORMAT = ENV.fetch('FILE_FORMAT', 'tiff')
    GDRIVE_FOLDER_ID = ENV.fetch('GDRIVE_FOLDER_ID', nil)

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
          Workers::PageWorker.perform_async(path)
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
      if !GDRIVE_FOLDER_ID
        logger.info('Skipped upload to Google Drive.')
        return
      end

      logger.info("Uploading finished pdf.")
      session = GoogleDrive::Session.from_config('config.json')
      session.upload_from_file("#{tmpdir}/postprocessed.pdf", safe_filename, { parents: [GDRIVE_FOLDER_ID], convert: false })
    end

    def verify
      # download
      # count pages
    end

    def safe_filename
      Time.now.strftime("%Y-%m-%d - %H_%M_%S.pdf")
    end

    class Postprocessor
      def on_success(_status, options)
        Job.new(options).postprocess_scanfiles
      end
    end
  end
end
