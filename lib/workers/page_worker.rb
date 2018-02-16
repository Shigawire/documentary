module Workers
  class PageWorker
    include Sidekiq::Worker

    sidekiq_options queue: :ocr

    def perform(path)
      Workflows::Page.new(path: Pathname.new(path)).process
    end
  end
end
