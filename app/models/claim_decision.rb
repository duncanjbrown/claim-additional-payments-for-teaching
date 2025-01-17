require "csv"

class ClaimDecision < ApplicationRecord
  self.primary_key = "application_id"

  def readonly?
    true
  end

  scope :yesterday, -> { where(decision_date: 1.day.ago.all_day) }
  scope :reporting_date, ->(date) { where(decision_date: date.all_day) }

  def self.to_csv
    CSV.generate(headers: true) do |csv|
      csv << attribute_names

      all.each do |row|
        csv << attribute_names.map { |attr| row.send(attr) }
      end
    end
  end
end
