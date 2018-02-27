class Command
  def self.call(cmd)
    escaped = cmd.gsub("\""){"\\\""}
    Logger.new(STDOUT).debug("Running Command \"#{escaped}\"")
    `bash -c "#{escaped} 2>&1"`.tap do
      if (status = $?.exitstatus) != 0
        raise "#{escaped} exited with status #{status}"
      end
    end
  end
end
