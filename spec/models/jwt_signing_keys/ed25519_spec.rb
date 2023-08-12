# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'JwtSigningKeys::Ed25519', type: :model do
  subject { JwtSigningKeys::Ed25519.new }
  
  context 'crypto verification' do
    it 'can sign (and verify) a message' do
      data = SecureRandom.uuid

      signature_bytes = subject.private_key.sign(data)

      expect(subject.public_key.verify(data, signature_bytes)).to be true
    end
  end
end
