require 'rails_helper'

RSpec.describe Character::CleanupStaleCharactersJob, type: :job do
  include ActiveJob::TestHelper
  
  subject(:job) { described_class.perform_later }

  before(:all) do
    @user = FactoryBot.create(:random_user)
  end

  it 'deletes stale unverified characters' do
    chara = FactoryBot.create(:random_character, user: @user, created_at: 10.years.ago)

    perform_enqueued_jobs { job }

    expect(Character.exists?(chara.id)).to be(false)
  end

  it 'does not delete stale verified characters' do
    chara = FactoryBot.create(:random_character, user: @user, created_at: 10.years.ago, verified_at: 3.years.ago)

    perform_enqueued_jobs { job }

    expect(Character.exists?(chara.id)).to be(true)
  end
  
  it 'does not delete freshly made characters' do
    chara = FactoryBot.create(:random_character, user: @user, created_at: 2.minutes.ago)

    perform_enqueued_jobs { job }

    expect(Character.exists?(chara.id)).to be(true)
  end

  after do
    clear_enqueued_jobs
    clear_performed_jobs
  end
end
