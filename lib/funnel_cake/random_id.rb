require 'active_support'

module FunnelCake
  class RandomId

    # Generates a random hex string of given length (16 by default)
    def self.generate(length=16)
      ActiveSupport::SecureRandom.hex(64).to_s[0..length]
    end

  end
end
