module Workers
  class ScanFileWorker
    include Sidekiq::Worker

    def perform(path)
      ScanFile.new(path: path).process
    end
  end
end
