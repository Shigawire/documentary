#!/usr/bin/env ruby

require_relative 'boot'
require 'sidekiq/api'
require 'i2c/drivers/lcd'

class LCD
  LCD_I2CADDRESS = ENV.fetch('LCD_I2CADDRESS', 0x27)

  def self.call
    new.loop
  end

  attr_accessor :logger, :display

  def initialize
    self.logger = Logger.new(STDOUT)
    begin
      self.display = I2C::Drivers::LCD::Display.new('/dev/i2c-1', LCD_I2CADDRESS, rows=20, cols=4)
    rescue
      self.logger.warn 'No display present'
    end
  end

  def is_scanning?
    begin
      return Command.('pgrep scanimage').length > 0
    rescue
      return false
    end
  end

  def row_1_text
    if is_scanning?
      'Scanning...'
    else
      queue_lengths_text
    end
  end

  def row_2_text
    return 'No scanjob present.' unless current_job
    "Current Job: #{current_job.lcd_status} (#{current_job.duration})"
  end

  def row_3_text
    return ''                        unless current_job
    return 'Postprocessing complete' if current_job.postprocessing_complete?
    current_pages.map(&:lcd_page_number).join('')
  end

  def row_4_text
    return ''             unless current_job || current_job.postprocessing_complete?
    return 'Uploading...' if current_job.uploading?
    current_pages.map(&:lcd_status).join('')
  end

  def queue_lengths_text
    "Jobs: #{pad num_jobs} Pages: #{pad num_pages}"
  end

  def num_jobs
    job_queue.size + (current_job ? 1 : 0)
  end

  def num_pages
    page_queue.size + page_workers.size
  end

  def current_pages
    # show the last finished plus current pages
    pages = current_job.processed_pages[0..(3 - (page_workers.length - 1))]
    pages += page_workers.map do |worker|
      page_filename = worker[2]['payload']['args'].first
      Workflows::Page.new(path: Pathname.new(page_filename))
    end
  end

  def current_job
    return nil unless current_job_dir
    Workflows::Job.new(Directory.new(path: Pathname.new(current_job_dir)))
  end

  def current_job_dir
    Redis.current.get('current_job')
  end

  def page_workers
    Sidekiq::Workers.new.select {|_,_,w| w['queue'] == 'page' }
  end

  def job_workers
    Sidekiq::Workers.new.select {|_,_,w| w['queue'] == 'job' }
  end

  def page_queue
    Sidekiq::Queue.new('page')
  end

  def job_queue
    Sidekiq::Queue.new('job')
  end

  def pad(number, characters = 2)
    "%02d" % number
  end

  def loop
    while true do
      if display
        display.clear
        display.text(row_1_text, 0)
        display.text(row_2_text, 1)
        display.text(row_3_text, 2)
        display.text(row_4_text, 3)
      else
        self.logger.debug ['', row_1_text, row_2_text, row_3_text, row_4_text].join("\n")
      end
        sleep 1
    end
  end
end

LCD.()
