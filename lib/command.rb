class Command
  def self.call(cmd)
    Logger.new(STDOUT).debug("Running Command \"#{cmd}\"")
    `#{cmd}`.tap do
      if (status = $?.exitstatus) != 0
        raise "#{cmd} exited with status #{status}"
      end
    end
  end
end
