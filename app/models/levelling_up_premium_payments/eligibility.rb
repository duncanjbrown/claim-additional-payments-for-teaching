module LevellingUpPremiumPayments
  class Eligibility < ApplicationRecord
    include EligibilityCheckable

    self.table_name = "levelling_up_premium_payments_eligibilities"
    has_one :claim, as: :eligibility, inverse_of: :eligibility
    belongs_to :current_school, optional: true, class_name: "School"

    # TODO: use first year of LUP for now but this must come from a PolicyConfiguration
    validates :award_amount, on: :amendment, award_range: {max: LevellingUpPremiumPayments::Award.max(AcademicYear.new(2022))}
    validates :eligible_degree_subject, on: [:"eligible-degree-subject"], inclusion: {in: [true, false], message: "Select yes if you have a degree in an eligible subject"}

    delegate :name, to: :current_school, prefix: true, allow_nil: true

    EDITABLE_ATTRIBUTES = [
      :nqt_in_academic_year_after_itt,
      :current_school_id,
      :employed_as_supply_teacher,
      :has_entire_term_contract,
      :employed_directly,
      :subject_to_formal_performance_action,
      :subject_to_disciplinary_action,
      :qualification,
      :eligible_itt_subject,
      :teaching_subject_now,
      :itt_academic_year,
      :eligible_degree_subject
    ].freeze

    AMENDABLE_ATTRIBUTES = [:award_amount].freeze

    ATTRIBUTE_DEPENDENCIES = {
      "employed_as_supply_teacher" => ["has_entire_term_contract", "employed_directly"],
      "qualification" => ["eligible_itt_subject", "teaching_subject_now"],
      "eligible_itt_subject" => ["teaching_subject_now", "eligible_degree_subject"],
      "itt_academic_year" => ["eligible_itt_subject"]
    }.freeze

    enum qualification: {
      postgraduate_itt: 0,
      undergraduate_itt: 1,
      assessment_only: 2,
      overseas_recognition: 3
    }

    enum eligible_itt_subject: {
      chemistry: 0,
      foreign_languages: 1,
      mathematics: 2,
      physics: 3,
      none_of_the_above: 4,
      computing: 5
    }, _prefix: :itt_subject

    # TODO this is *inadequate* for future policy years
    # Whatever the current policy year is, a teacher should be able to
    # choose from the previous five academic years. To cover the life
    # of LUP, this needs to be from 2017/2018 to 2023/2024 (inclusive) but remember
    # only the previous five should ever be selectable (and valid) for the
    # current policy year.
    #
    # You can get the previous five academic years for display (and validation) from
    # the `JourneySubjectEligibilityChecker.selectable_itt_years_for_claim_year` method
    enum itt_academic_year: {
      AcademicYear.new(2017) => AcademicYear::Type.new.serialize(AcademicYear.new(2017)),
      AcademicYear.new(2018) => AcademicYear::Type.new.serialize(AcademicYear.new(2018)),
      AcademicYear.new(2019) => AcademicYear::Type.new.serialize(AcademicYear.new(2019)),
      AcademicYear.new(2020) => AcademicYear::Type.new.serialize(AcademicYear.new(2020)),
      AcademicYear.new(2021) => AcademicYear::Type.new.serialize(AcademicYear.new(2021)),
      AcademicYear.new => AcademicYear::Type.new.serialize(AcademicYear.new)
    }

    # TODO don't know if we need this
    before_save :set_qualification_if_trainee_teacher, if: :nqt_in_academic_year_after_itt_changed?

    def policy
      LevellingUpPremiumPayments
    end

    def award_amount
      super || calculate_award_amount
    end

    def reset_dependent_answers(reset_attrs = [])
      attrs = ineligible? ? changed.concat(reset_attrs) : changed

      ATTRIBUTE_DEPENDENCIES.each do |attribute_name, dependent_attribute_names|
        dependent_attribute_names.each do |dependent_attribute_name|
          write_attribute(dependent_attribute_name, nil) if attrs.include?(attribute_name)
        end
      end
    end

    def submit!
      self.award_amount = award_amount
      save!
    end

    # TODO: Not used any more
    def eligible_now_and_again_sometime?
      eligible_now? && any_future_policy_years?
    end

    def indicated_ineligible_itt_subject?
      return false if eligible_itt_subject.blank?

      args = {claim_year: claim_year, itt_year: itt_academic_year}

      if args.values.any?(&:blank?)
        # trainee teacher who won't have given their ITT year
        eligible_itt_subject.present? && !eligible_itt_subject.to_sym.in?(JourneySubjectEligibilityChecker.fixed_lup_subject_symbols)
      else
        itt_subject_checker = JourneySubjectEligibilityChecker.new(args)
        eligible_itt_subject.present? && !eligible_itt_subject.to_sym.in?(itt_subject_checker.current_subject_symbols(policy))
      end
    end

    private

    def indicated_ecp_only_itt_subject?
      eligible_itt_subject.present? && (eligible_itt_subject.to_sym == :foreign_languages)
    end

    def specific_eligible_now_attributes?
      eligible_itt_subject_or_relevant_degree?
    end

    def eligible_itt_subject_or_relevant_degree?
      good_itt_subject? || eligible_degree?
    end

    def good_itt_subject?
      return false if eligible_itt_subject.blank?

      args = {claim_year: claim_year, itt_year: itt_academic_year}

      if args.values.any?(&:blank?)
        # trainee teacher who won't have given their ITT year
        eligible_itt_subject.present? && eligible_itt_subject.to_sym.in?(JourneySubjectEligibilityChecker.fixed_lup_subject_symbols)
      else
        itt_subject_checker = JourneySubjectEligibilityChecker.new(args)
        eligible_itt_subject.to_sym.in?(itt_subject_checker.current_subject_symbols(policy))
      end
    end

    def eligible_degree?
      eligible_degree_subject?
    end

    def specific_ineligible_attributes?
      indicated_ecp_only_itt_subject? || trainee_teacher_with_ineligible_itt_subject? || ineligible_itt_subject_and_no_relevant_degree?
    end

    def trainee_teacher_with_ineligible_itt_subject?
      trainee_teacher? && indicated_ineligible_itt_subject?
    end

    def ineligible_itt_subject_and_no_relevant_degree?
      indicated_ineligible_itt_subject? && lacks_eligible_degree?
    end

    def specific_eligible_later_attributes?
      trainee_teacher? && eligible_itt_subject_or_relevant_degree?
    end

    def lacks_eligible_degree?
      eligible_degree_subject == false
    end

    def calculate_award_amount
      # This doesn't need to be a BigDecimal but maintaining interface
      BigDecimal LevellingUpPremiumPayments::Award.new(school: current_school, year: claim_year).amount_in_pounds if current_school.present?
    end

    # TODO originally copied from ECP. Don't know what this is.
    def set_qualification_if_trainee_teacher
      return unless trainee_teacher?

      self.qualification = :postgraduate_itt
    end
  end
end
