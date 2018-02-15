module Workers
  class ScanJobWorker
    include Sidekiq::Worker

    def perform(tmpdir)
      ScanJob.new(tmpdir).perform
    end
  end
end
