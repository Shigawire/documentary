module Workflows
  class Page
    attr_accessor :path, :ocr_result

    def initialize(path:)
      self.path = path
    end

    def process
      deskew
      perform_ocr
      destroy! if empty?
    end

    def deskew
    end

    def perform_ocr
      self.ocr_result = Command.("tesseract -l deu+eng #{path} #{path} pdf")
    end

    def empty?
      ocr_result.include? 'empty file'
    end

    def destroy!
      # delete me, because I am empty or ugly :(
      # What's beauty, anyways? Perfectly aligned rectangles?
      # correct me, instead! #deskew
    end

    def deskew
    end
  end
end
