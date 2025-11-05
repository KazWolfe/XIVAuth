require "rails_helper"

RSpec.describe FFXIV::LodestoneProfile do
  let(:fixtures_path) { Rails.root.join("spec/fixtures/lodestone/characters") }

  def load_fixture(name)
    File.read(fixtures_path.join(name))
  end

  describe ".new with html:" do
    it "parses a visible character with a verification code" do
      html = load_fixture("character_present_code.html")
      profile = described_class.new(43809410, html: html)

      expect(profile).to be_valid
      expect(profile.character_visible?).to be(true)
      expect(profile.character_profile_visible?).to be(true)

      # Exact identity fields
      expect(profile.name).to eq("Abe Eon")
      expect(profile.title).to eq("King Bean")
      expect(profile.world).to eq("Lamia")
      expect(profile.datacenter).to eq("Primal")

      expect(profile.avatar).to match(/https:\/\/img2\.finalfantasyxiv\.com\/f\/[0-9a-f_]+fc0\.jpg/)
      expect(profile.portrait).to match(/https:\/\/img2\.finalfantasyxiv\.com\/f\/[0-9a-f_]+fl0\.jpg/)

      # Bio should include the code block from the fixture
      expect(profile.bio).to include("XIVAUTH:")

      # Class levels should include some jobs with integer values
      expect(profile.class_levels).to be_a(Hash)
      expect(profile.class_levels).not_to be_empty
      expect(profile.class_levels.values).to all(be_a(Integer))

      # Free company info present in the fixture
      expect(profile.free_company).to include(:name, :id)
      expect(profile.free_company[:name]).to eq("Friendly Fire")
      expect(profile.free_company[:id]).to eq(9231112598714485863)
      expect(profile.paid_character?).to be(true)

      # Optional extras (not asserting exact values to avoid brittleness)
      expect { profile.nameday }.not_to raise_error
      expect { profile.guardian }.not_to raise_error
      expect { profile.city_state }.not_to raise_error
      expect(profile.grand_company).to eq({ company: "Immortal Flames", rank: "Flame Captain" })
      expect(profile.pvp_team).to eq({ name: "End Bringers", id: "4db96525339b69aac24329a13aaa086994bca30d" })
    end

    it "detects a hidden character page" do
      html = load_fixture("private_character.html")
      profile = described_class.new(1234, html: html)

      expect(profile.character_visible?).to be(false)
      profile.valid?
      expect(profile.failure_reason).to eq(:hidden_character)
      expect(profile.errors[:base].join).to match(/is marked as hidden or private/i)
    end

    it "detects a private profile page" do
      html = load_fixture("private_profile.html")
      profile = described_class.new(1234, html: html)

      expect(profile.character_visible?).to be(true)
      expect(profile.character_profile_visible?).to be(false)

      expect(profile.name).to eq("Vento Aureo")
      expect(profile.world).to eq("Twintania")
      expect(profile.datacenter).to eq("Light")

      expect(profile.avatar).to match(/https:\/\/img2\.finalfantasyxiv\.com\/f\/[0-9a-f_]+fc0\.jpg/)
      expect(profile.portrait).to match(/https:\/\/img2\.finalfantasyxiv\.com\/f\/[0-9a-f_]+fl0\.jpg/)

      profile.valid?
      expect(profile.failure_reason).to eq(:profile_private)
      expect(profile).to be_valid
    end

    it "detects a 404 not found page" do
      html = load_fixture("character_not_found.html")
      profile = described_class.new(0, html: html)

      expect(profile.character_exists?).to be(false)
      profile.valid?
      expect(profile.failure_reason).to eq(:not_found)
      expect(profile.errors[:base].join).to match(/could not be found/i)
    end
  end
end
