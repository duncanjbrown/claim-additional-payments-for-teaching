require "rails_helper"

describe Admin::ClaimsHelper do
  let(:claim_school) { schools(:penistone_grammar_school) }
  let(:current_school) { create(:school, :student_loan_eligible) }

  describe "#admin_personal_details" do
    let(:claim) do
      build(
        :claim,
        first_name: "Bruce",
        surname: "Wayne",
        teacher_reference_number: "1234567",
        national_insurance_number: "QQ123456C",
        email_address: "test@email.com",
        address_line_1: "Flat 1",
        address_line_2: "1 Test Road",
        address_line_3: "Test Town",
        postcode: "AB1 2CD",
        date_of_birth: Date.new(1901, 1, 1),
      )
    end

    it "includes an array of questions and answers" do
      expected_answers = [
        [I18n.t("admin.teacher_reference_number"), "1234567"],
        [I18n.t("verified_fields.full_name").capitalize, "Bruce Wayne"],
        [I18n.t("verified_fields.date_of_birth").capitalize, "01/01/1901"],
        [I18n.t("admin.national_insurance_number"), "QQ123456C"],
        [I18n.t("verified_fields.address").capitalize, "Flat 1<br>1 Test Road<br>Test Town<br>AB1 2CD"],
        [I18n.t("admin.email_address"), "test@email.com"],
      ]

      expect(helper.admin_personal_details(claim)).to eq expected_answers
    end
  end

  describe "#admin_student_loan_details" do
    let(:claim) do
      build(
        :claim,
        student_loan_plan: :plan_1,
        eligibility: build(:student_loans_eligibility, student_loan_repayment_amount: 1234),
      )
    end

    it "includes an array of questions and answers" do
      expect(helper.admin_student_loan_details(claim)).to eq([
        [I18n.t("student_loans.admin.student_loan_repayment_amount"), "£1,234.00"],
        [I18n.t("student_loans.admin.student_loan_repayment_plan"), "Plan 1"],
      ])
    end
  end

  describe "#admin_submission_details" do
    let(:claim) { create(:claim, :submitted) }

    it "includes an array of questions and answers" do
      expect(helper.admin_submission_details(claim)).to eq([
        [I18n.t("admin.started_at"), l(claim.created_at)],
        [I18n.t("admin.submitted_at"), l(claim.submitted_at)],
        [I18n.t("admin.check_deadline"), l(claim.check_deadline_date)],
      ])
    end

    context "when the claim is approaching its deadline" do
      let(:claim) { create(:claim, :submitted, submitted_at: (Claim::CHECK_DEADLINE - 1.week).ago) }

      it "always includes the deadline date" do
        expect(helper.admin_submission_details(claim)[2].last).to have_content(l(claim.check_deadline_date))
      end

      it "includes the deadline warning" do
        expect(helper.admin_submission_details(claim)[2].last).to have_selector(".tag--warning")
      end
    end
  end

  describe "#admin_check_details" do
    let(:claim) { create(:claim, :submitted) }
    let(:check) { Check.create!(claim: claim, checked_by: "user-123", result: :approved) }

    it "includes an array of details about the check" do
      expect(helper.admin_check_details(check)).to eq([
        [I18n.t("admin.check.checked_at"), l(check.created_at)],
        [I18n.t("admin.check.result"), check.result.capitalize],
      ])
    end

    context "when notes are saved with the check" do
      let(:check) { Check.create!(claim: claim, checked_by: "user-123", result: :approved, notes: "abc\nxyz") }

      it "includes the notes" do
        expect(helper.admin_check_details(check)).to include([I18n.t("admin.check.notes"), simple_format(check.notes, class: "govuk-body")])
      end
    end
  end

  describe "#check_deadline_warning" do
    subject { helper.check_deadline_warning(claim) }
    before { travel_to Time.zone.local(2019, 10, 11, 7, 0, 0) }
    after { travel_back }

    context "when a claim is approaching it's deadline" do
      let(:claim) { build(:claim, :submitted, submitted_at: (Claim::CHECK_DEADLINE - 1.week).ago) }

      it { is_expected.to have_content("7 days") }
      it { is_expected.to have_selector(".tag--warning") }
    end

    context "when a claim has passed it's deadline" do
      let(:claim) { build(:claim, :submitted, submitted_at: (Claim::CHECK_DEADLINE + 4.weeks).ago) }

      it { is_expected.to have_content("-28 days") }
      it { is_expected.to have_selector(".tag--alert") }
    end

    context "when a claim is not near it's deadline" do
      let(:claim) { build(:claim, :submitted, submitted_at: 1.day.ago) }

      it { is_expected.to be_nil }
    end
  end

  describe "#matching_attributes" do
    let(:first_claim) {
      build(
        :claim,
        teacher_reference_number: "0902344",
        national_insurance_number: "QQ891011C",
        email_address: "genghis.khan@mongol-empire.com",
        bank_account_number: "34682151",
        bank_sort_code: "972654",
        building_society_roll_number: "123456789/ABCD",
      )
    }
    let(:second_claim) { build(:claim, :submitted, teacher_reference_number: first_claim.teacher_reference_number, national_insurance_number: first_claim.national_insurance_number, building_society_roll_number: first_claim.building_society_roll_number) }
    subject { helper.matching_attributes(first_claim, second_claim) }

    it "returns the humanised names of the matching attributes" do
      expect(subject).to eq(["Building society roll number", "National insurance number", "Teacher reference number"])
    end

    it "does not consider nil building society roll number to be a match" do
      [first_claim, second_claim].each { |claim| claim.building_society_roll_number = nil }
      expect(subject).to eq(["National insurance number", "Teacher reference number"])
    end
  end
end
