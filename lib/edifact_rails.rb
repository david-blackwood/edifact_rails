module EdifactRails
  def self.parse(string)
    "I'm gonna PAAAAAARSE #{string}"
  end

  def self.parse_file(file_path)
    File.foreach(file_path) do |line|
      puts line
    end
  end
end