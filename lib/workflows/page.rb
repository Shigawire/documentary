module Workflows
  class Page
    FILE_FORMAT = ENV.fetch('FILE_FORMAT', 'tiff')
    attr_accessor :path, :ocr_result

    def initialize(path:)
      self.path = path
    end

    def process
      enhance
      deskew
      perform_ocr
      destroy! if empty?
    end

    def enhance
      Command.("mogrify #{path} -normalize -level 10%,90% -sharpen 0x1")
    end

    def deskew
      Command.("convert #{path} -deskew 80% +repage #{page_basename}_deskewed.#{FILE_FORMAT}")
    end

    def perform_ocr
      self.ocr_result = Command.("tesseract -l deu+eng #{page_basename}_deskewed.#{FILE_FORMAT} #{path} pdf")
    end

    def empty?
      ocr_result.include? 'empty file'
    end

    def destroy!
      # delete me, because I am empty or ugly :(
      # What's beauty, anyways? Perfectly aligned rectangles?
      # correct me, instead! #deskew
    end

    def page_basename
      path.basename(".#{FILE_FORMAT}")
    end
  end
end
