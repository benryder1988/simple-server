class DistrictReportService
  include SQLHelpers
  MAX_MONTHS_OF_DATA = 24

  def initialize(district:, selected_date:, current_user:)
    @current_user = current_user
    @organizations = Pundit.policy_scope(current_user, [:cohort_report, Organization]).order(:name)
    @district = district
    @facilities = district.facilities
    @selected_date = selected_date.end_of_month
    @data = {
      controlled_patients: {},
      registrations: {},
      cumulative_registrations: 0,
      quarterly_registrations: [],
      top_district_benchmarks: {}
    }.with_indifferent_access
  end

  attr_reader :current_user
  attr_reader :data
  attr_reader :district
  attr_reader :facilities
  attr_reader :organizations
  attr_reader :selected_date

  def call
    compile_control_and_registration_data
    compile_cohort_trend_data
    compile_benchmarks

    data
  end

  def compile_control_and_registration_data
    months_of_data = [registration_counts.to_a.size, MAX_MONTHS_OF_DATA].min
    @data[:cumulative_registrations] = lookup_registration_count(selected_date)
    (-months_of_data + 1).upto(0).each do |n|
      time = selected_date.advance(months: n).end_of_month
      formatted_period = time.to_s(:month_year)

      @data[:controlled_patients][formatted_period] = controlled_patients_count(time)
      @data[:registrations][formatted_period] = lookup_registration_count(time)
    end
  end

  # We want to return cohort data for the current quarter for the selected date, and then
  # the previous three quarters. Each quarter cohort is made up of patients registered
  # in the previous quarter who has had a follow up visit in the current quarter.
  def compile_cohort_trend_data
    Quarter.new(date: selected_date).downto(3).each do |results_quarter|
      cohort_quarter = results_quarter.previous_quarter

      period = {cohort_period: :quarter,
                registration_quarter: cohort_quarter.number,
                registration_year: cohort_quarter.year}
      query = MyFacilities::BloodPressureControlQuery.new(facilities: @facilities, cohort_period: period)
      @data[:quarterly_registrations] << {
        results_in: format_quarter(results_quarter),
        patients_registered: format_quarter(cohort_quarter),
        registered: query.cohort_registrations.count,
        controlled: query.cohort_controlled_bps.count,
        no_bp: query.cohort_missed_visits_count,
        uncontrolled: query.cohort_uncontrolled_bps.count
      }.with_indifferent_access
    end
  end

  def compile_benchmarks
    @data[:top_district_benchmarks].merge!(top_district_benchmarks)
  end

  def format_quarter(quarter)
    "#{quarter.year} Q#{quarter.number}"
  end

  def lookup_registration_count(date)
    lookup_date = date.beginning_of_month.to_date
    registration_counts[lookup_date]
  end

  def registration_counts
    @registration_counts ||= district.patients.with_hypertension
      .group_by_period(:month, :recorded_at, range: MAX_MONTHS_OF_DATA.months.ago..selected_date)
      .count
      .each_with_object(Hash.new(0)) { |(date, count), hsh|
        hsh[:running_total] += count
        hsh[date] = hsh[:running_total]
      }.delete_if { |date, count| count == 0 }.except(:running_total)
  end

  def controlled_patients_count(time)
    ControlledPatientsQuery.call(facilities: facilities, time: time).count
  end

  def top_district_benchmarks
    TopRegionService.new(organizations, selected_date).call
  end
end
