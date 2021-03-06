require "rails_helper"
require "tasks/scripts/link_teleconsultation_medical_officers"

RSpec.describe LinkTeleconsultationMedicalOfficers do
  context "for each facility" do
    let!(:facility_1_phone_numbers) { %w[00000000 11111111] }
    let!(:facility_2_phone_numbers) { %w[222222222 3333333333] }

    let!(:facility_1) {
      create(:facility,
        enable_teleconsultation: true,
        teleconsultation_phone_numbers: [
          {isd_code: "+91", phone_number: facility_1_phone_numbers.first},
          {isd_code: "+91", phone_number: facility_1_phone_numbers.second}
        ])
    }

    let!(:facility_2) {
      create(:facility,
        enable_teleconsultation: true,
        teleconsultation_phone_numbers: [
          {isd_code: "+91", phone_number: facility_2_phone_numbers.first},
          {isd_code: "+91", phone_number: facility_2_phone_numbers.second}
        ])
    }

    it "finds all medical officers with matching phone_numbers and links them" do
      facility_1_mos = facility_1_phone_numbers.map { |phone_number|
        create(:user, phone_number: phone_number)
      }

      facility_2_mos = facility_2_phone_numbers.map { |phone_number|
        create(:user, phone_number: phone_number)
      }

      described_class.call

      expect(facility_1.teleconsultation_medical_officers).to match_array facility_1_mos
      expect(facility_2.teleconsultation_medical_officers).to match_array facility_2_mos
    end

    it "finds all medical officers with matching teleconsult_phone_numbers and links them" do
      facility_1_mos = facility_1_phone_numbers.map { |phone_number|
        create(:user, teleconsultation_phone_number: phone_number)
      }

      facility_2_mos = facility_2_phone_numbers.map { |phone_number|
        create(:user, teleconsultation_phone_number: phone_number)
      }

      described_class.call

      expect(facility_1.teleconsultation_medical_officers).to match_array facility_1_mos
      expect(facility_2.teleconsultation_medical_officers).to match_array facility_2_mos
    end

    it "keeps the already linked MOs" do
      existing_mo = create(:user)
      facility_1.teleconsultation_medical_officers = [existing_mo]

      facility_1_mos = facility_1_phone_numbers.map { |phone_number|
        create(:user, teleconsultation_phone_number: phone_number)
      }

      described_class.call

      expect(facility_1.reload.teleconsultation_medical_officers).to match_array [facility_1_mos, existing_mo].flatten
    end

    it "skips facilities without any linkable MOs" do
      described_class.call

      expect(facility_1.teleconsultation_medical_officers).to be_empty
      expect(facility_2.teleconsultation_medical_officers).to be_empty
    end
  end
end
