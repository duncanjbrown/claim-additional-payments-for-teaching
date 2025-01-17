class IneligibilityReasonChecker
  def initialize(current_claim)
    @current_claim = current_claim
  end

  def reason
    if current_school?
      :current_school
    elsif generic?
      :generic
    elsif ecp_only_trainee_teacher?
      :ecp_only_trainee_teacher
    elsif trainee_teaching_lacking_both_valid_itt_subject_and_degree?
      :trainee_teaching_lacking_both_valid_itt_subject_and_degree
    elsif lack_both_valid_itt_subject_and_degree?
      :lack_both_valid_itt_subject_and_degree
    elsif would_be_eligible_for_lup_only_except_for_insufficient_teaching?
      :would_be_eligible_for_lup_only_except_for_insufficient_teaching
    elsif would_be_eligible_for_ecp_only_except_for_insufficient_teaching?
      :would_be_eligible_for_ecp_only_except_for_insufficient_teaching
    elsif would_be_eligible_for_both_ecp_and_lup_except_for_insufficient_teaching?
      :would_be_eligible_for_both_ecp_and_lup_except_for_insufficient_teaching
    elsif bad_itt_year_for_ecp?
      :bad_itt_year_for_ecp
    elsif bad_itt_subject_for_ecp?
      :bad_itt_subject_for_ecp
    elsif no_ecp_subjects_that_itt_year?
      :no_ecp_subjects_that_itt_year
    end
  end

  private

  def current_school?
    school = @current_claim.eligibility.current_school

    [
      school.present?,
      !EarlyCareerPayments::SchoolEligibility.new(school).eligible?,
      !LevellingUpPremiumPayments::SchoolEligibility.new(school).eligible?
    ].all?
  end

  def generic?
    [
      @current_claim.eligibility.has_entire_term_contract == false,
      @current_claim.eligibility.employed_directly == false,
      @current_claim.eligibility.subject_to_formal_performance_action?,
      @current_claim.eligibility.subject_to_disciplinary_action?,
      @current_claim.eligibility.itt_academic_year == AcademicYear.new
    ].any?
  end

  def ecp_only_trainee_teacher?
    [
      !LevellingUpPremiumPayments::SchoolEligibility.new(@current_claim.eligibility.current_school).eligible?,
      @current_claim.eligibility.nqt_in_academic_year_after_itt == false
    ].all?
  end

  def trainee_teaching_lacking_both_valid_itt_subject_and_degree?
    [
      LevellingUpPremiumPayments::SchoolEligibility.new(@current_claim.eligibility.current_school).eligible?,
      @current_claim.eligibility.nqt_in_academic_year_after_itt == false,
      lack_both_valid_itt_subject_and_degree?
    ].all?
  end

  def lack_both_valid_itt_subject_and_degree?
    lup_claim = @current_claim.for_policy(LevellingUpPremiumPayments)

    [
      subject_invalid_for_ecp?,
      lup_claim.eligibility.eligible_degree_subject == false
    ].all?
  end

  def would_be_eligible_for_lup_only_except_for_insufficient_teaching?
    would_be_eligible_for_one_policy_only_except_for_insufficient_teaching?(LevellingUpPremiumPayments)
  end

  def would_be_eligible_for_one_policy_only_except_for_insufficient_teaching?(policy)
    other_policy = policy == EarlyCareerPayments ? LevellingUpPremiumPayments : EarlyCareerPayments

    [
      eligible_with_sufficient_teaching?(policy),
      !eligible_with_sufficient_teaching?(other_policy)
    ].all?
  end

  def eligible_with_sufficient_teaching?(policy)
    eligibility = @current_claim.for_policy(policy).eligibility
    teaching_before = eligibility.teaching_subject_now
    eligible_with_sufficient_teaching = nil

    # check it and put it back
    eligibility.transaction do
      eligibility.update(teaching_subject_now: true)
      eligible_with_sufficient_teaching = eligibility.status.in?([:eligible_now, :eligible_later])
      eligibility.update(teaching_subject_now: teaching_before)
    end

    eligible_with_sufficient_teaching
  end

  def would_be_eligible_for_ecp_only_except_for_insufficient_teaching?
    would_be_eligible_for_one_policy_only_except_for_insufficient_teaching?(EarlyCareerPayments)
  end

  def would_be_eligible_for_both_ecp_and_lup_except_for_insufficient_teaching?
    [
      eligible_with_sufficient_teaching?(EarlyCareerPayments),
      eligible_with_sufficient_teaching?(LevellingUpPremiumPayments)
    ].all?
  end

  def subject_invalid_for_ecp?
    !@current_claim.eligibility.eligible_itt_subject&.to_sym&.in?(ecp_subject_options)
  end

  def ecp_subject_options
    JourneySubjectEligibilityChecker.new(claim_year: @current_claim.policy_year, itt_year: @current_claim.eligibility.itt_academic_year).current_and_future_subject_symbols(EarlyCareerPayments)
  end

  def bad_itt_year_for_ecp?
    [
      ecp_subject_options.one?,
      subject_invalid_for_ecp?,
      school_eligible_for_ecp_but_not_lup?(@current_claim.eligibility.current_school)
    ].all?
  end

  def school_eligible_for_ecp_but_not_lup?(school)
    EarlyCareerPayments::SchoolEligibility.new(school).eligible? && !LevellingUpPremiumPayments::SchoolEligibility.new(school).eligible?
  end

  def bad_itt_subject_for_ecp?
    [
      ecp_subject_options.many?,
      subject_invalid_for_ecp?,
      school_eligible_for_ecp_but_not_lup?(@current_claim.eligibility.current_school)
    ].all?
  end

  def no_ecp_subjects_that_itt_year?
    [
      ecp_subject_options.none?,
      school_eligible_for_ecp_but_not_lup?(@current_claim.eligibility.current_school)
    ].all?
  end
end
