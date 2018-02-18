#!/usr/bin/env ruby

require 'google_drive'
require 'json'
require 'fileutils'

def main
  unless ENV['GOOGLE_OAUTH_CLIENT_ID'] && ENV['GOOGLE_OAUTH_CLIENT_SECRET']
    puts "GOOGLE_OAUTH_CLIENT_ID or GOOGLE_OAUTH_CLIENT_SECRET not set."
    return
  end

  credentials = {
    "client_id": "#{ENV['GOOGLE_OAUTH_CLIENT_ID']}",
    "client_secret": "#{ENV['GOOGLE_OAUTH_CLIENT_SECRET']}"
  }

  File.open('config.json', 'w') do |f|
    f.write(JSON.pretty_generate(credentials))
  end

  session = GoogleDrive::Session.from_config("config.json")

  puts "Done. You are now authenticated against Google Drive."
end

main
