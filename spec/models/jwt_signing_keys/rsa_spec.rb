# frozen_string_literal: true

require 'rails_helper'

RSpec.describe JwtSigningKeys::RSA, type: :model do
  subject { described_class.new(name: "rspec_rsa_#{SecureRandom.uuid}", size: 1024) }

  context 'crypto verification' do
    it 'can sign and verify a message' do
      digest = OpenSSL::Digest.new('SHA256')
      data = "This is a super secret message. #{SecureRandom.alphanumeric}"

      signature_bytes = subject.private_key.sign(digest, data)
      expect(subject.public_key.verify(digest, signature_bytes, data)).to be true
    end

    it 'has a public key that matches the private key' do
      expect(subject.public_key.to_pem(nil)).to eq(subject.private_key.public_key.to_pem(nil))
    end
  end

  context 'ActiveRecord shenanigans' do
    it 'is not valid without a name' do
      subject.name = nil
      expect(subject).not_to be_valid
    end

    it 'contains a valid keypair at initialization' do
      expect(subject.public_key).to be_an_instance_of(OpenSSL::PKey::RSA)

      expect(subject.private_key).to be_an_instance_of(OpenSSL::PKey::RSA)
      expect(subject.private_key.private?).to be true

      expect(subject.public_key).to be_an_instance_of(OpenSSL::PKey::RSA)
      expect(subject.public_key.private?).to be false
    end

    it 'correctly persists the keypair' do
      subject.save

      ci = described_class.find_by_name(subject.name)
      expect(ci.raw_private_key).to eq(subject.raw_private_key)
      expect(ci.raw_public_key).to eq(subject.raw_public_key)
    end

    it "doesn't allow updating the key size" do
      subject.size = 2048

      expect(subject.size).to eq(1024)
    end
  end
end
