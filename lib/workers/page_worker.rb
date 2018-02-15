module Workers
  class PageWorker
    include Sidekiq::Worker

    sidekiq_options queue: :ocr

    def perform(path)
      Workflows::Page.new(path: path).process
    end
  end
end
