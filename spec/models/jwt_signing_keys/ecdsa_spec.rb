# frozen_string_literal: true

require 'rails_helper'

RSpec.describe JwtSigningKeys::ECDSA, type: :model do
  subject { described_class.new(name: "rspec_ecdsa_#{SecureRandom.uuid}", curve: 'prime256v1') }

  context 'crypto verification' do
    it 'can sign and verify a message' do
      digest = OpenSSL::Digest.new('SHA256')
      data = "This is a super secret message. #{SecureRandom.alphanumeric}"

      signature_bytes = subject.private_key.sign(digest, data)
      expect(subject.public_key.verify(digest, signature_bytes, data)).to be true
    end

    it 'has a public key that matches the private key' do
      # Crypto... hissss. We store public keys as a proper EC, which isn't how `.public_key` is normally
      # calculated. So, we'll just shunt it into working.
      expect(subject.public_key.public_key&.to_bn).to eq(subject.private_key.public_key.to_bn)
    end
  end

  context 'ActiveRecord shenanigans' do
    it 'is not valid without a name' do
      subject.name = nil
      expect(subject).not_to be_valid
    end

    it 'contains a valid keypair at initialization' do
      expect(subject.public_key).to be_an_instance_of(OpenSSL::PKey::EC)

      expect(subject.private_key).to be_an_instance_of(OpenSSL::PKey::EC)
      expect(subject.private_key.private?).to be true

      expect(subject.public_key).to be_an_instance_of(OpenSSL::PKey::EC)
      expect(subject.public_key.private?).to be false
    end

    it 'correctly persists the keypair' do
      subject.save

      ci = described_class.find_by_name(subject.name)
      expect(ci.raw_private_key).to eq(subject.raw_private_key)
      expect(ci.raw_public_key).to eq(subject.raw_public_key)
    end

    it "doesn't allow updating the curve" do
      subject.curve = 'foobarbaz'

      expect(subject.curve).to eq('prime256v1')
    end

    it 'allows setting a curve on creation' do
      ec_key = described_class.new(name: 'curve_override_test', curve: 'secp384r1')
      expect(ec_key.curve).to eq('secp384r1')
    end
  end
end
