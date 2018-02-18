module Workflows
  class Job
    FILE_FORMAT = ENV.fetch('FILE_FORMAT', 'tiff')
    GDRIVE_FOLDER_ID = ENV.fetch('GDRIVE_FOLDER_ID', nil)
    EMAIL_ADDRESS = ENV.fetch('EMAIL_ADDRESS', nil)

    attr_accessor :directory, :files_to_process, :logger

    def initialize(directory)
      self.logger = Logger.new(STDOUT)
      self.directory = directory
      self.files_to_process = Dir.glob("#{directory.path}/*.#{FILE_FORMAT}")
    end

    def perform
      if files_to_process.none?
        logger.info('No files to proces, cleaning up.')
        clean_up
      end

      batch = Sidekiq::Batch.new
      batch.on(:complete, Postprocessor, directory: directory.to_h)
      batch.jobs do
        files_to_process.each do |path|
          Workers::PageWorker.perform_async(path)
        end
      end
    end

    def postprocess_scanfiles(any_pages_failed:)
      unless any_pages_failed
        merge
        upload
        verify
      else
        logger.error('Skipping postprocessing because some pages failed to process.')
      end

      clean_up
    end

    def merge
      logger.info("Merging all PDFs.")
      cmd = "gs -dDownsampleColorImages=true -dColorImageResolution=150 -sDEVICE=pdfwrite -dPDFA=2 -dBATCH -dNOPAUSE -sProcessColorModel=DeviceRGB -sColorConversionStrategy=/RGB -sPDFACompatibilityPolicy=1 -sOutputFile=#{postprocessed_file} #{directory.path}/*.#{FILE_FORMAT}.pdf"
      Command.(cmd)
    end

    def upload
      if !GDRIVE_FOLDER_ID
        logger.info('Skipped upload to Google Drive.')
        return
      end

      logger.info("Uploading finished pdf.")
      session = GoogleDrive::Session.from_config('config.json')
      session.upload_from_file(postprocessed_file, safe_filename, { parents: [GDRIVE_FOLDER_ID], convert: false })
    end

    def send_email
      if !EMAIL_ADDRESS
        logger.info('Skipped email sending.')
        return
      end

      Mailer.(postprocessed_file)
    end

    def verify
      # download
      # count pages
    end

    def postprocessed_file
      "#{directory.path}/postprocessed.pdf"
    end

    def clean_up
      if !directory.to_be_removed
        logger.info("Keeping directory #{directory.path}.")
        return
      end

      FileUtils.rm_rf(directory.path)
      logger.info("Removed directory #{directory.path}.")
    end

    def safe_filename
      Time.now.strftime("%Y-%m-%d - %H_%M_%S.pdf")
    end

    class Postprocessor
      def on_complete(status, options)
        directory = Directory.from_h(options.fetch('directory'))
        Job.new(directory).postprocess_scanfiles(any_pages_failed: status.failures != 0)
      end
    end
  end
end
