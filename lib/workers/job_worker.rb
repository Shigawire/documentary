module Workers
  class JobWorker
    include Sidekiq::Worker

    def perform(tmpdir)
      Workflows::Job.new(tmpdir).perform
    end
  end
end
