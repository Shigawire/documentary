require_relative '../command'

module Workers
  class OCRWorker
    include Sidekiq::Worker

    def perform(path)
      Command.("tesseract -l deu+eng #{path} #{path} pdf")
    end
  end
end
