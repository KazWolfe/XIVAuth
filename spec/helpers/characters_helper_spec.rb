require 'rails_helper'

# Specs in this file have access to a helper object that includes
# the CharactersHelper. For example:
#
# describe CharactersHelper do
#   describe "string concat" do
#     it "concats two strings with spaces" do
#       expect(helper.concat_strings("this","that")).to eq("this that")
#     end
#   end
# end
RSpec.describe CharactersHelper, type: :helper do
  context "the id extractor" do
    it "can handle a raw number" do
      expect(helper.extract_id("12345678")).to eq("12345678")
    end

    it "can handle HTTPS urls" do
      url = "https://na.finalfantasyxiv.com/lodestone/character/12345678/"
      expect(helper.extract_id(url)).to eq("12345678")
    end

    it "can handle HTTP urls" do
      url = "http://na.finalfantasyxiv.com/lodestone/character/12345678/"
      expect(helper.extract_id(url)).to eq("12345678")
    end

    it "can handle different regions" do
      url = "https://fr.finalfantasyxiv.com/lodestone/character/12345678/"
      expect(helper.extract_id(url)).to eq("12345678")
    end

    it "can handle no trailing slash" do
      url = "https://fr.finalfantasyxiv.com/lodestone/character/12345678"
      expect(helper.extract_id(url)).to eq("12345678")
    end

    it "returns nil if an invalid url is passed" do
      url = "https://na.finalfantasyxiv.com/lodestone/my/"
      expect(helper.extract_id(url)).to be_nil
    end
  end
end
