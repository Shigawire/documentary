require_relative 'command'

class ScanFile
  attr_accessor :filename, :fullpath, :ocr_result

  def initialize(fullpath:)
    self.fullpath = fullpath
  end

  def process
    deskew
    perform_ocr
    destroy! if is_empty?
  end

  def deskew
  end

  def perform_ocr
    self.ocr_result = Command.("tesseract -l deu+eng #{fullpath} #{fullpath} pdf")
    #self.ocr_result = Workers::OCRWorker.new.perform(fullpath)
  end

  def is_empty?
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
