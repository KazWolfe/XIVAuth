require 'xivapi'

module FFXIV
  class XIVAPIService
    def initialize
      @client = XIVAPI::Client.new
      super
    end

    def worlds
      @client.search(indexes: 'worlds', filters: ['IsPublic=1'], columns: %w[ID Name DataCenter IsPublic])
    end
  end
end
