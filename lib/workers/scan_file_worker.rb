module Workers
  class ScanFileWorker
    include Sidekiq::Worker

    sidekiq_options queue: :ocr

    def perform(path)
      ScanFile.new(path: path).process
    end
  end
end
