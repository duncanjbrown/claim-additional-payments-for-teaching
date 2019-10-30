require "rails_helper"

RSpec.describe Claim::PermittedParameters do
  let(:student_loan_claim) { Claim.new(eligibility: StudentLoans::Eligibility.new) }
  let(:editable_attributes_for_student_loans_claim) do
    [
      :address_line_1,
      :address_line_2,
      :address_line_3,
      :address_line_4,
      :postcode,
      :payroll_gender,
      :teacher_reference_number,
      :national_insurance_number,
      :has_student_loan,
      :student_loan_country,
      :student_loan_courses,
      :student_loan_start_date,
      :email_address,
      :bank_sort_code,
      :bank_account_number,
      :banking_name,
      :building_society_roll_number,
      eligibility_attributes: [
        :qts_award_year,
        :claim_school_id,
        :employment_status,
        :current_school_id,
        :had_leadership_position,
        :taught_eligible_subjects,
        :mostly_performed_leadership_duties,
        :student_loan_repayment_amount,
        :biology_taught,
        :chemistry_taught,
        :physics_taught,
        :computer_science_taught,
        :languages_taught,
      ],
    ]
  end

  subject(:permitted_parameters) { Claim::PermittedParameters.new(student_loan_claim) }

  describe "#keys" do
    it "returns all the editable attributes for a claim, including those for its eligibility" do
      expect(permitted_parameters.keys).to eq editable_attributes_for_student_loans_claim
    end

    it "will exclude any attributes that have been set based on a GOV.UK Verify response" do
      student_loan_claim.verified_fields = ["payroll_gender", "address_line_1"]

      expected_attributes = editable_attributes_for_student_loans_claim - [:address_line_1, :payroll_gender]

      expect(permitted_parameters.keys).to eq expected_attributes
    end
  end
end