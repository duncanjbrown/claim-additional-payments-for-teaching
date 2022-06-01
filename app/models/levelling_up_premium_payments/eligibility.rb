module LevellingUpPremiumPayments
  class Eligibility < ApplicationRecord
    self.table_name = "levelling_up_premium_payments_eligibilities"
    has_one :claim, as: :eligibility, inverse_of: :eligibility
    belongs_to :current_school, optional: true, class_name: "School"

    # use first year of LUP for now but this must come from a PolicyConfiguration
    validates :award_amount, on: :amendment, award_range: {max: LevellingUpPremiumPayments::Award.max(AcademicYear.new(2022))}
    validates :eligible_degree_subject, on: [:"eligible-degree-subject", :submit], inclusion: {in: [true, false], message: "Select yes if you have a degree in an eligible subject"}

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
      :award_amount,
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
      none_of_the_above: 4
    }, _prefix: :itt_subject

    enum itt_academic_year: {
      AcademicYear.new(2018) => AcademicYear::Type.new.serialize(AcademicYear.new(2018)),
      AcademicYear.new(2019) => AcademicYear::Type.new.serialize(AcademicYear.new(2019)),
      AcademicYear.new(2020) => AcademicYear::Type.new.serialize(AcademicYear.new(2020)),
      AcademicYear.new => AcademicYear::Type.new.serialize(AcademicYear.new)
    }

    def policy
      LevellingUpPremiumPayments
    end

    def ineligible?
      ineligible_nqt_in_academic_year_after_itt? ||
        has_ineligible_school? ||
        no_entire_term_contract? ||
        not_employed_directly? ||
        poor_performance? ||
        with_eligible_none_of_the_above_without_eligible_degree_subject? ||
        with_eligible_degree_subject_not_teaching_subject_now? ||
        ineligible_cohort?
    end

    def eligible_now?
      !ineligible?
    end

    def eligible_later?
      same_as_now
    end

    def award_amount
      calculate_award_amount
    end

    def reset_dependent_answers
      ATTRIBUTE_DEPENDENCIES.each do |attribute_name, dependent_attribute_names|
        dependent_attribute_names.each do |dependent_attribute_name|
          write_attribute(dependent_attribute_name, nil) if changed.include?(attribute_name)
        end
      end
    end

    def eligible_none_of_the_above?
      itt_subject_none_of_the_above?
    end

    private

    def has_ineligible_school?
      current_school.present? and !LevellingUpPremiumPayments::SchoolEligibility.new(current_school).eligible?
    end

    # unlike ECP, the situation cannot change for a teacher in the future
    def same_as_now
      eligible_now?
    end

    def calculate_award_amount
      # use first year of LUP for now but this must come from a PolicyConfiguration
      BigDecimal LevellingUpPremiumPayments::Award.new(school: current_school, year: AcademicYear.new(2022)).amount_in_pounds if current_school.present?
    end

    def with_eligible_none_of_the_above_without_eligible_degree_subject?
      eligible_none_of_the_above? && without_eligible_degree_subject?
    end

    def with_eligible_degree_subject_not_teaching_subject_now?
      eligible_none_of_the_above? && eligible_degree_subject && not_teaching_subject_now?
    end

    def not_teaching_subject_now?
      teaching_subject_now == false
    end

    def without_eligible_degree_subject?
      eligible_degree_subject == false
    end

    # Start LUP duplicates

    def ineligible_nqt_in_academic_year_after_itt?
      return false if trainee_teacher_in_2021?

      nqt_in_academic_year_after_itt == false
    end

    def trainee_teacher_in_2021?
      nqt_in_academic_year_after_itt == false && PolicyConfiguration.for(policy).current_academic_year == "2021/2022"
    end

    def no_entire_term_contract?
      employed_as_supply_teacher? && has_entire_term_contract == false
    end

    def not_employed_directly?
      employed_as_supply_teacher? && employed_directly == false
    end

    def poor_performance?
      subject_to_formal_performance_action? ||
        subject_to_disciplinary_action?
    end

    def ineligible_cohort?
      itt_academic_year == AcademicYear.new
    end
  end
end
