class FacilityGroup < ApplicationRecord
  extend FriendlyId
  extend RegionSource
  default_scope -> { kept }

  belongs_to :organization
  belongs_to :protocol

  has_many :facilities, dependent: :nullify
  has_many :users, through: :facilities

  has_many :patients, through: :facilities, source: :registered_patients
  alias_method :registered_patients, :patients
  has_many :assigned_patients, through: :facilities, source: :assigned_patients
  has_many :blood_pressures, through: :facilities
  has_many :blood_sugars, through: :facilities
  has_many :encounters, through: :facilities
  has_many :prescription_drugs, through: :facilities
  has_many :appointments, through: :facilities
  has_many :teleconsultations, through: :facilities

  has_many :medical_histories, through: :patients
  has_many :communications, through: :appointments

  validates :name, presence: true
  validates :organization, presence: true

  friendly_id :name, use: :slugged

  auto_strip_attributes :name, squish: true, upcase_first: true
  attribute :enable_diabetes_management, :boolean

  def registered_hypertension_patients
    Patient.with_hypertension.where(registration_facility: facilities)
  end

  def toggle_diabetes_management
    if enable_diabetes_management
      set_diabetes_management(true)
    elsif diabetes_enabled?
      set_diabetes_management(false)
    end
  end

  def report_on_patients
    Patient.where(registration_facility: facilities)
  end

  def diabetes_enabled?
    facilities.where(enable_diabetes_management: false).count.zero?
  end

  def discardable?
    facilities.none? && patients.none? && blood_pressures.none? && blood_sugars.none? && appointments.none?
  end

  def dashboard_analytics(period:, prev_periods:, include_current_period: true)
    query = DistrictAnalyticsQuery.new(self, period, prev_periods, include_current_period: include_current_period)
    query.call
  end

  def cohort_analytics(period:, prev_periods:)
    query = CohortAnalyticsQuery.new(self, period: period, prev_periods: prev_periods)
    query.call
  end

  private

  def set_diabetes_management(value)
    facilities.update(enable_diabetes_management: value).map(&:valid?).all?
  end
end
