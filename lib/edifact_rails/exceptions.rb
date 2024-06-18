module EdifactRails
  class UnrecognizedFormat < StandardError
    def initialize
      super("Unrecognized EDI format. Accepted formats: Edifact, Tradacoms, ANSIX12. File must begin with UNA, UNB, STX, or ISA.")
    end
  end
end