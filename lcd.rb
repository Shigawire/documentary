#!/usr/bin/env ruby

require_relative 'boot'
require 'sidekiq/api'
require 'i2c/drivers/lcd'

class LCD
  LCD_I2CADDRESS = ENV.fetch('LCD_I2CADDRESS', 0x27)
  DISPLAY_TIMEOUT = 15

  def self.call
    new.loop
  end

  attr_accessor :logger, :display, :status, :display_status

  def initialize
    self.logger = Logger.new(STDOUT)
    begin
      self.display = I2C::Drivers::LCD::Display.new('/dev/i2c-1', LCD_I2CADDRESS, rows=20, cols=4)
      self.display.clear
    rescue
      self.logger.warn 'No display present.'
      sleep
    end
  end

  def display_on
    return if display_on?
    display.clear
    display.on
    display.backlight_on
    self.display_status = true
  end

  def display_off
    return if display_off?
    display.off
    display.backlight_off
    self.display_status = false
  end

  def display_on?
    self.display_status == true
  end

  def display_off?
    self.display_status == false
  end

  def scanning?
    Redis.current.get('scanning') == 'true'
  end

  def row_1_text
    return 'Scanning...' if scanning?
    queue_lengths_text
  end

  def row_2_text
    return 'No scanjob present' unless current_job
    "Job: #{current_job.lcd_status}   #{current_job.duration}"
  end

  def row_3_text
    return '' unless current_job
    return 'Postprocessed' if current_job.postprocessing_complete?
    current_pages.map(&:lcd_page_number).join('')
  end

  def row_4_text
    return '' unless current_job
    return '' if current_job.postprocessing_complete?
    return 'Uploading...' if current_job.uploading?
    current_pages.map(&:lcd_status).join('')
  end

  def queue_lengths_text
    "Jobs: #{pad num_jobs} Pages: #{pad num_pages}"
  end

  def num_jobs
    Redis.current.llen('jobs')
  end

  def num_pages
    page_queue.size + page_workers.size
  end

  def current_pages
    # show the last finished plus current pages
    #pages = current_job.processed_pages[0..(3 - (page_workers.length - 1))]
    page_workers.map do |worker|
      page_filename = worker[2]['payload']['args'].first
      Workflows::Page.new(path: Pathname.new(page_filename))
    end
  end

  def current_job
    return nil unless current_job_dir
    Workflows::Job.new(Directory.new(path: Pathname.new(current_job_dir)))
  end

  def current_job_dir
    Redis.current.lindex('jobs', 0)
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

  def pad(number, characters = 2)
    "%02d" % number
  end

  def display_print(text, line)
    display.text(text.upcase.ljust(20), line)
  end

  def print_status
    display_print(row_1_text, 0)
    display_print(row_2_text, 1)
    display_print(row_3_text, 2)
    display_print(row_4_text, 3)
  end

  def loop
    display_timeout = Time.now
    while true do
      if current_job || scanning?
        display_on
        display_timeout = Time.now
        print_status
      end
      display_off if (Time.now - display_timeout) > DISPLAY_TIMEOUT
      sleep 1
    end
  end
end

LCD.()
