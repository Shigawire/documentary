class Mailer
  EMAIL_ADDRESS = ENV.fetch('EMAIL_ADDRESS', nil)
  SMTP_HOST = ENV.fetch('SMTP_HOST', nil)
  SMTP_USERNAME = ENV.fetch('SMTP_HOST', nil)
  SMTP_PASSWORD = ENV.fetch('SMTP_PASSWORD', nil)


  def self.call(file)
    unless SMTP_HOST && SMTP_USERNAME && SMTP_PASSWORD
      raise 'No valid SMTP configuration present.'
    end

    Mail.defaults do
      delivery_method :smtp, {
        :address => SMTP_HOST,
        :port => 587,
        :user_name => SMTP_USERNAME,
        :password => SMTP_PASSWORD,
        :authentication => :plain,
        :enable_starttls_auto => true
      }
    end

    Mail.deliver do
      from     'scanbot@urmel.io'
      to       EMAIL_ADDRESS
      subject  'Scanfile from Scanbot'
      body     File.read(file)
      add_file "#{file}"
    end
  end
end
