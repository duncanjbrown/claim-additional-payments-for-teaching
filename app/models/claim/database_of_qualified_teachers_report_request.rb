require "csv"

class Claim
  class DatabaseOfQualifiedTeachersReportRequest
    HEADERS = [
      "Claim reference",
      "Teacher reference number",
    ].freeze

    def initialize(claims)
      @claims = claims
    end

    def to_csv
      CSV.generate(write_headers: true, headers: HEADERS) do |csv|
        @claims.each do |claim|
          csv << [
            claim.reference,
            claim.teacher_reference_number,
          ]
        end
      end
    end
  end
end
