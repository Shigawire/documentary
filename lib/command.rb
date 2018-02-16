class Command
  def self.call(cmd)
    Logger.new(STDOUT).debug("Running Command \"#{cmd}\"")
    `bash -c "#{cmd} 2>&1"`.tap do
      if (status = $?.exitstatus) != 0
        raise "#{cmd} exited with status #{status}"
      end
    end
  end
end
