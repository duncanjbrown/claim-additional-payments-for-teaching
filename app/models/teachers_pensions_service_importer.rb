require "file_download"
require "csv"

class TeachersPensionsServiceImporter
  attr_reader :errors, :rows

  EXPECTED_HEADERS = [
    "Teacher reference number",
    "NINO",
    "Start Date",
    "End Date",
    "Annual salary",
    "Monthly pay",
    "N/A",
    "LA URN",
    "School URN"
  ].freeze

  def initialize(file)
    @errors = []
    @rows = parse_csv(file)
    check_headers
  end

  def run
    ActiveRecord::Base.transaction do
      rows.each do |row|
        tps_data = row_to_tps(row)
        tps_data.save! if tps_data.valid?
      end
    end
  end

  private

  def check_headers
    return unless rows

    missing_headers = EXPECTED_HEADERS - rows.headers
    errors.append("The selected file is missing some expected columns: #{missing_headers.join(", ")}") if missing_headers.any?
  end

  def parse_csv(file)
    if file.nil?
      errors.append("Select a file")
      nil
    else
      CSV.read(file.to_io, headers: true, encoding: "BOM|UTF-8")
    end
  rescue CSV::MalformedCSVError
    errors.append("The selected file must be a CSV")
    nil
  end

  def row_to_tps(row)
    tps_data = TeachersPensionsService.new(teacher_reference_number: row.fetch("Teacher reference number"))
    # tps_data.national_insurance_number = row.fetch("NINO")
    tps_data.start_date = row.fetch("Start Date")
    tps_data.end_date = row.fetch("End Date")
    tps_data.la_urn = row.fetch("LA URN")
    tps_data.school_urn = row.fetch("School URN")
    tps_data
  end
end
