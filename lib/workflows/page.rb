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
      reader = PDF::Reader.new(pdf_path)
      reader.pages.first.text.empty?
    end

    def pdf_path
      "#{path}.pdf"
    end

    def lcd_page_number
      File.basename(path, '.*').ljust(5)
    end

    def lcd_status
      status = case
      when !deskewed?
        'DESK'
      when !normalized?
        'NORM'
      when !ocr_performed?
        'OCR'
      when deleted?
        'DEL'
      when ocr_performed?
        'DONE'
      end
      return status.ljust(5)
    end

    def finished?
      ocr_performed? || deleted?
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
      File.rename(pdf_path, delete_path)
    end

    def delete_path
      "#{path}.del"
    end

    def deleted?
      File.size? delete_path
    end

    def deskewed?
      File.size? deskewed_path
    end

    def normalized?
      File.size? normalized_path
    end

    def ocr_performed?
      File.size? pdf_path
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
