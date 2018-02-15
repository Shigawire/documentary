module Workers
  class ScanJobWorker
    include Sidekiq::Worker
    def perform(scanjob)
      scanjob.perform
    end
  end
end
