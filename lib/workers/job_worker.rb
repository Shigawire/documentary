module Workers
  class JobWorker
    include Sidekiq::Worker

    def perform(options)
      directory = Directory.from_h(options.fetch('directory'))
      Workflows::Job.new(directory).perform
    end
  end
end
