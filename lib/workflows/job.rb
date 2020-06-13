module Workflows
  class Job
    FILE_FORMAT = ENV.fetch('FILE_FORMAT', 'tiff')
    GDRIVE_FOLDER_ID = ENV.fetch('GDRIVE_FOLDER_ID', nil)
    EMAIL_ADDRESS = ENV.fetch('EMAIL_ADDRESS', nil)
    NORMALIZED_SUFFIX = '_normalized'.freeze
    UPLOAD_URL = ENV.fetch('UPLOAD_URL', nil)

    attr_accessor :directory, :files_to_process, :logger

    def initialize(directory)
      self.logger = Logger.new(STDOUT)
      self.directory = directory
      self.files_to_process = Dir.glob("#{directory.path}/*.#{FILE_FORMAT}").grep(/\d\.#{Regexp.quote(FILE_FORMAT)}$/)
    end

    def perform
      Redis.current.rpush('jobs', directory.path)
      if files_to_process.none?
        logger.info('No files to process, cleaning up.')
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
        upload_gdrive
        upload
        send_email
        verify
      else
        logger.error('Skipping postprocessing because some pages failed to process.')
      end

      clean_up
    end

    def merge
      logger.info("Merging all PDFs.")
      cmd = "convert -limit memory 0 -limit map 0 #{directory.path}/*#{NORMALIZED_SUFFIX}.#{FILE_FORMAT} - | zip > #{postprocessed_compressed_file}"
      Command.call(cmd)
    end

    def upload_gdrive
      if !GDRIVE_FOLDER_ID
        logger.info('Skipped upload to Google Drive.')
        return
      end

      logger.info("Uploading finished pdf.")
      session = GoogleDrive::Session.from_config('/data/google-oauth-config.json')
      session.upload_from_file(postprocessed_file, safe_filename, { parents: [GDRIVE_FOLDER_ID], convert: false })
    end

    def upload
      if !UPLOAD_URL
        logger.info('Skipping uploading to UPLOAD_URL.')
        return
      end

      logger.info('Uploading file to UPLOAD_URL.')

      RestClient.post(
        UPLOAD_URL,
        File.read(postprocessed_compressed_file),
        content_type: 'application/octet-stream'
      )

      logger.info('Uploaded file to UPLOAD_URL.')
    end

    def postprocessed_compressed_file
      "#{postprocessed_file}"
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
      "#{directory.path}/postprocessed.pdf.zip"
    end

    def clean_up
      Redis.current.lpop('jobs')

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

    def postprocessing_complete?
      processed_pages.size == pages.size
    end

    def uploading?
      File.size? postprocessed_file
    end

    def lcd_status
      "#{pad processed_pages.size}/#{pad pages.size}"
    end

    def pad(number, characters = 2)
      "%02d" % number
    end

    def duration
      # get date of one of the scanfiles
      duration = Time.now - File.ctime(files_to_process.first)
      seconds_to_time(duration.to_i)
    end

    def seconds_to_time(seconds)
      [seconds / 60 % 60, seconds % 60].map { |t| t.to_s.rjust(2,'0') }.join(':')
    end

    def pages
      files_to_process.map { |f| Workflows::Page.new(path: Pathname.new(f)) }
    end

    def processed_pages
      pages.select { |p| p.finished? }
    end

    class Postprocessor
      def on_complete(status, options)
        directory = Directory.from_h(options.fetch('directory'))
        Job.new(directory).postprocess_scanfiles(any_pages_failed: status.failures != 0)
      end
    end
  end
end
