class Mailer
  FROM_EMAIL_ADDRESS = ENV.fetch('FROM_EMAIL_ADDRESS', nil)
  TO_EMAIL_ADDRESS = ENV.fetch('EMAIL_ADDRESS', nil)
  SMTP_HOST = ENV.fetch('SMTP_HOST', nil)
  SMTP_USERNAME = ENV.fetch('SMTP_USERNAME', nil)
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
      from     FROM_EMAIL_ADDRESS
      to       TO_EMAIL_ADDRESS
      subject  'Scanfile from documentary'
      body     ''
      add_file "#{file}"
    end
  end
end
