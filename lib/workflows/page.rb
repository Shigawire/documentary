module Workflows
  class Page
    FILE_FORMAT = ENV.fetch('FILE_FORMAT', 'tiff')
    attr_accessor :path, :ocr_result

    def initialize(path:)
      self.path = path
    end

    def process
      deskew
      normalize
      perform_ocr
      destroy! if empty?
    end

    def empty?
      ocr_result.match(/Empty page!!/)
    end

    def pdf_path
      "#{path}.pdf"
    end

    private

    def deskew
      Command.("convert #{path} -deskew 80% +repage #{deskewed_path}")
    end
    
    def normalize
      Command.("convert #{deskewed_path} -normalize #{normalized_path}")
    end

    def perform_ocr
      self.ocr_result = Command.("tesseract -l deu+eng #{normalized_path} #{path} pdf")
    end

    def destroy!
      FileUtils.rm pdf_path
    end

    def page_basename
      path.basename(".#{FILE_FORMAT}")
    end

    def normalized_path
      path.dirname.join("#{page_basename}_normalized.#{FILE_FORMAT}")
    end

    def deskewed_path
      path.dirname.join("#{page_basename}_deskewed.#{FILE_FORMAT}")
    end
  end
end
