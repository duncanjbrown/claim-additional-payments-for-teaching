require "rails_helper"

RSpec.describe EarlyCareerPayments::SlugSequence do
  subject(:slug_sequence) { EarlyCareerPayments::SlugSequence.new(current_claim) }

  let(:eligibility) { build(:early_career_payments_eligibility, :eligible) }
  let(:eligibility_lup) { build(:levelling_up_premium_payments_eligibility, :eligible) }

  let(:claim) { build(:claim, academic_year: AcademicYear.new(2021), eligibility: eligibility) }
  let(:lup_claim) { build(:claim, academic_year: AcademicYear.new(2021), eligibility: eligibility_lup) }
  let(:current_claim) { CurrentClaim.new(claims: [claim, lup_claim]) }

  describe "The sequence as defined by #slugs" do
    it "excludes the 'ineligible' slug if the claim's eligibility is undetermined" do
      expect(slug_sequence.slugs).not_to include("ineligible")
    end

    it "excludes supply teacher detail slugs if they aren't a supply teacher" do
      claim.eligibility.employed_as_supply_teacher = false

      expect(slug_sequence.slugs).not_to include("entire-term-contract", "employed-directly")
    end

    it "includes supply teacher detail slugs if they are a supply teacher" do
      claim.eligibility.employed_as_supply_teacher = true

      expect(slug_sequence.slugs).to include("entire-term-contract", "employed-directly")
    end

    context "when 'provide_mobile_number' is 'No'" do
      it "excludes the 'mobile-number' slug" do
        claim.provide_mobile_number = false

        expect(slug_sequence.slugs).not_to include("mobile-number")
      end

      it "excludes the 'mobile-verification' slug" do
        claim.provide_mobile_number = false

        expect(slug_sequence.slugs).not_to include("mobile-verification")
      end
    end

    context "when 'provide_mobile_number' is 'Yes'" do
      it "includes the 'mobile-number' slug" do
        claim.provide_mobile_number = true

        expect(slug_sequence.slugs).to include("mobile-number")
      end

      it "includes the 'mobile-verification' slug" do
        claim.provide_mobile_number = true

        expect(slug_sequence.slugs).to include("mobile-verification")
      end
    end

    context "when claim is eligible" do
      let(:eligibility) { build(:early_career_payments_eligibility, :eligible) }

      it "includes the 'eligibility_confirmed' slug" do
        expect(slug_sequence.slugs).to include("eligibility-confirmed")
      end
    end

    context "when claim is ineligible" do
      let(:eligibility) { build(:early_career_payments_eligibility, :ineligible) }
      let(:eligibility_lup) { build(:levelling_up_premium_payments_eligibility, :ineligible) }

      it "includes the 'ineligible' slug" do
        expect(slug_sequence.slugs).to include("ineligible")
      end

      it "excludes the 'eligibility-confirmed' slug" do
        expect(slug_sequence.slugs).not_to include("eligibility-confirmed")
      end
    end

    context "when claim is not eligible later" do
      let(:eligibility) do
        build(
          :early_career_payments_eligibility,
          :eligible,
          eligible_itt_subject: "mathematics",
          itt_academic_year: AcademicYear::Type.new.serialize(AcademicYear.new(2018))
        )
      end

      it "excludes the 'eligible-later' slug" do
        expect(slug_sequence.slugs).not_to include("eligible-later")
      end
    end

    context "when claim payment details are 'personal bank account'" do
      it "excludes the 'building-society-account' slug" do
        claim.bank_or_building_society = :personal_bank_account

        expect(slug_sequence.slugs).not_to include("building-society-account")
      end
    end

    context "when claim payment details are 'building society'" do
      it "excludes the 'personal-bank-account' slug" do
        claim.bank_or_building_society = :building_society

        expect(slug_sequence.slugs).not_to include("personal-bank-account")
      end
    end

    context "when the answer to 'paying off student loan' is 'Yes'" do
      it "excludes 'masters-doctoral-loan' slug" do
        claim.has_student_loan = true

        expected_slugs = %w[
          current-school
          nqt-in-academic-year-after-itt
          supply-teacher
          poor-performance
          qualification
          itt-year
          eligible-itt-subject
          teaching-subject-now
          check-your-answers-part-one
          eligibility-confirmed
          information-provided
          personal-details
          postcode-search
          no-address-found
          select-home-address
          address
          email-address
          email-verification
          provide-mobile-number
          mobile-number
          mobile-verification
          bank-or-building-society
          personal-bank-account
          building-society-account
          gender
          teacher-reference-number
          student-loan
          student-loan-country
          student-loan-how-many-courses
          student-loan-start-date
          masters-loan
          doctoral-loan
          check-your-answers
        ]

        expect(slug_sequence.slugs).to eq expected_slugs
      end
    end

    context "when the answer to 'paying off student loan' is 'No' AND to 'paying of a postgraduate masters/doctoral loans' is 'Yes'" do
      it "excludes 'student-loan-country', 'student-loan-how-many-courses' and, 'student-loan-start-date' slugs" do
        claim.has_student_loan = false
        claim.has_masters_doctoral_loan = true

        expected_slugs = %w[
          current-school
          nqt-in-academic-year-after-itt
          supply-teacher
          poor-performance
          qualification
          itt-year
          eligible-itt-subject
          teaching-subject-now
          check-your-answers-part-one
          eligibility-confirmed
          information-provided
          personal-details
          postcode-search
          no-address-found
          select-home-address
          address
          email-address
          email-verification
          provide-mobile-number
          mobile-number
          mobile-verification
          bank-or-building-society
          personal-bank-account
          building-society-account
          gender
          teacher-reference-number
          student-loan
          masters-doctoral-loan
          masters-loan
          doctoral-loan
          check-your-answers
        ]

        expect(slug_sequence.slugs).to eq expected_slugs
      end
    end

    context "when the answer to 'student loan - home address ' is 'Scotland' OR 'Northern Ireland'" do
      let(:expected_slugs) do
        %w[
          current-school
          nqt-in-academic-year-after-itt
          supply-teacher
          poor-performance
          qualification
          itt-year
          eligible-itt-subject
          teaching-subject-now
          check-your-answers-part-one
          eligibility-confirmed
          information-provided
          personal-details
          postcode-search
          no-address-found
          select-home-address
          address
          email-address
          email-verification
          provide-mobile-number
          mobile-number
          mobile-verification
          bank-or-building-society
          personal-bank-account
          building-society-account
          gender
          teacher-reference-number
          student-loan
          student-loan-country
          masters-loan
          doctoral-loan
          check-your-answers
        ]
      end

      before do
        claim.has_student_loan = true
      end

      it "excludes 'student-loan-how-many-courses', 'student-loan-start-date' - Northern Ireland - slugs" do
        claim.student_loan_country = StudentLoan::NORTHERN_IRELAND

        expect(slug_sequence.slugs).to eq expected_slugs
      end

      it "excludes 'student-loan-how-many-courses', 'student-loan-start-date' - Scotland - slugs" do
        claim.student_loan_country = StudentLoan::SCOTLAND

        expect(slug_sequence.slugs).to eq expected_slugs
      end
    end

    context "when the answer to 'paying off student loan' is 'No' AND to 'paying of a postgraduate masters/doctoral loans' is 'No'" do
      it "excludes 'student-loan-country', 'student-loan-how-many-courses', 'student-loan-start-date', 'masters-loan' and 'doctoral-loan' slugs" do
        claim.has_student_loan = false
        claim.has_masters_doctoral_loan = false

        expected_slugs = %w[
          current-school
          nqt-in-academic-year-after-itt
          supply-teacher
          poor-performance
          qualification
          itt-year
          eligible-itt-subject
          teaching-subject-now
          check-your-answers-part-one
          eligibility-confirmed
          information-provided
          personal-details
          postcode-search
          no-address-found
          select-home-address
          address
          email-address
          email-verification
          provide-mobile-number
          mobile-number
          mobile-verification
          bank-or-building-society
          personal-bank-account
          building-society-account
          gender
          teacher-reference-number
          student-loan
          masters-doctoral-loan
          check-your-answers
        ]

        expect(slug_sequence.slugs).to eq expected_slugs
      end
    end
  end

  describe "eligibility affect on slugs" do
    let(:ecp_claim) { build(:claim, eligibility: ecp_eligibility) }
    let(:lup_claim) { build(:claim, eligibility: lup_eligibility) }
    let(:current_claim) { CurrentClaim.new(claims: [ecp_claim, lup_claim]) }

    subject { described_class.new(current_claim).slugs }

    context "current claim is :eligible_now" do
      let(:ecp_eligibility) { build(:early_career_payments_eligibility, :eligible_later) }
      let(:lup_eligibility) { build(:levelling_up_premium_payments_eligibility, :eligible_now) }

      it { is_expected.to include("eligibility-confirmed") }
      it { is_expected.not_to include("eligible-later", "ineligible") }
    end

    context "current claim is :eligible_later" do
      let(:ecp_eligibility) { build(:early_career_payments_eligibility, :ineligible) }
      let(:lup_eligibility) { build(:levelling_up_premium_payments_eligibility, :eligible_later) }

      it { is_expected.to include("eligible-later") }
      it { is_expected.not_to include("eligibility-confirmed") }
    end

    context "current claim is :ineligible" do
      let(:ecp_eligibility) { build(:early_career_payments_eligibility, :ineligible) }
      let(:lup_eligibility) { build(:levelling_up_premium_payments_eligibility, :ineligible) }

      it { is_expected.to include("ineligible") }
      it { is_expected.not_to include("eligibility-confirmed", "eligible-later") }
    end
  end
end
