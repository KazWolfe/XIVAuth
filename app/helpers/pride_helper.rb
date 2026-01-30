# frozen_string_literal: true

module PrideHelper
  PRIDE_FLAGS = %w[
    rainbow
    transgender
    bisexual
    lesbian
    asexual
    gay
    demi
    nonbinary
  ].freeze

  def current_pride_flag_class
    # Use the request UUID to deterministically select a flag
    # This ensures the same flag is shown throughout a request
    index = request.uuid.hash.abs % PRIDE_FLAGS.length
    flag = PRIDE_FLAGS[index]

    "pride-brand--#{flag}"
  end
end
