class OrganizationDistrict < Struct.new(:district_name, :organization)
  def district_slug(district_name)
    district_name.split(" ").select(&:present?).join("-").downcase
  end

  def dashboard_analytics
    {
      registered_patients_by_facility: RegisteredPatientsInDistrictQuery
                                         .new(district_name: district_name)
                                         .call
    }
  end
end
