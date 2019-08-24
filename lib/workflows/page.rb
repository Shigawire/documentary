module Workflows
  class Page
    FILE_FORMAT = ENV.fetch('FILE_FORMAT', 'tiff')
    NORMALIZED_SUFFIX = '_normalized'.freeze
    attr_accessor :path

    def initialize(path:)
      self.path = path
    end

    def process
      deskew
      normalize
    end

    def pdf_path
      "#{path}.pdf"
    end

    def lcd_page_number
      File.basename(path, '.*').ljust(5)
    end

    def lcd_status
      status =
        case
        when !deskewed?
          'DESK'
        when !normalized?
          'NORM'
        when normalized?
          'DONE'
        end

      status.ljust(5)
    end

    def finished?
      normalized?
    end

    private

    def deskew
      Command.call("convert #{path} -deskew 80% +repage #{deskewed_path}")
    end

    def normalize
      Command.call("convert #{deskewed_path} -normalize #{normalized_path}")
    end

    def deskewed?
      File.size? deskewed_path
    end

    def normalized?
      File.size? normalized_path
    end

    def page_basename
      path.basename(".#{FILE_FORMAT}")
    end

    def normalized_path
      path.dirname.join("#{page_basename}#{NORMALIZED_SUFFIX}.#{FILE_FORMAT}")
    end

    def deskewed_path
      path.dirname.join("#{page_basename}_deskewed.#{FILE_FORMAT}")
    end
  end
end
