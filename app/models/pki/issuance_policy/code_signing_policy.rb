class PKI::IssuancePolicy::CodeSigningPolicy < PKI::IssuancePolicy::Base
  register_certificate_type "code_signing"

  def self.allowed_subject_types = [User, Team]

  def common_name
    case subject
    when User then "[XIVAuth CodeSign] #{subject.display_name}"
    when Team then "[XIVAuth CodeSign] #{subject.name}"
    else "[XIVAuth CodeSign] #{subject.id}"
    end
  end

  def validity_period = 1.year

  def key_usage = %w[digitalSignature]

  def extended_key_usage = %w[codeSigning]
end
