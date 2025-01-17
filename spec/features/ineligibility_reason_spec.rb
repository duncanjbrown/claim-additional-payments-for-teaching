require "rails_helper"

RSpec.feature "Ineligibility reason" do
  let(:lup_and_ecp_school) { schools(:hampstead_school) }
  let(:ecp_only_school) { create(:school, :early_career_payments_eligible) }
  let(:primary_school) { create(:school, :early_career_payments_ineligible) }

  before { visit new_claim_path(LevellingUpPremiumPayments.routing_name) }

  context "supply teacher" do
    before do
      navigate_to_supply_teacher_subquestions
    end

    scenario "short-term" do
      choose "No"
      click_on "Continue"

      expect(page).to have_css("div#generic")
    end

    scenario "agency" do
      choose "Yes"
      click_on "Continue"

      choose "No"
      click_on "Continue"

      expect(page).to have_css("div#generic")
    end
  end

  context "bad performance" do
    before do
      navigate_to_performance_questions
    end

    scenario "formal performance action" do
      choose "claim_eligibility_attributes_subject_to_formal_performance_action_true"
      choose "claim_eligibility_attributes_subject_to_disciplinary_action_false"
      click_on "Continue"

      expect(page).to have_css("div#generic")
    end

    scenario "disciplinary action" do
      choose "claim_eligibility_attributes_subject_to_formal_performance_action_false"
      choose "claim_eligibility_attributes_subject_to_disciplinary_action_true"
      click_on "Continue"

      expect(page).to have_css("div#generic")
    end

    scenario "formal performance and disciplinary action" do
      choose "claim_eligibility_attributes_subject_to_formal_performance_action_true"
      choose "claim_eligibility_attributes_subject_to_disciplinary_action_true"
      click_on "Continue"

      expect(page).to have_css("div#generic")
    end
  end

  context "ITT year" do
    context "LUP and ECP school" do
      before do
        navigate_to_year_selection(lup_and_ecp_school)
      end

      scenario "None of the above" do
        choose "None of the above"
        click_on "Continue"

        expect(page).to have_css("div#generic")
      end
    end
  end

  context "teaching requirement" do
    context "ineligible for ECP" do
      before do
        navigate_to_year_selection(lup_and_ecp_school)
      end

      scenario "do not teach LUP subjects" do
        select_itt_year(AcademicYear.new(2021))

        choose "Mathematics"
        click_on "Continue"

        choose "No"
        click_on "Continue"

        expect(page).to have_css("div#would_be_eligible_for_lup_only_except_for_insufficient_teaching")
      end
    end

    context "ineligible for LUP" do
      before do
        navigate_to_year_selection(ecp_only_school)
      end

      scenario "do not teach ECP subjects" do
        select_itt_year(AcademicYear.new(2020))

        choose "Mathematics"
        click_on "Continue"

        choose "No"
        click_on "Continue"

        expect(page).to have_css("div#would_be_eligible_for_ecp_only_except_for_insufficient_teaching")
      end
    end

    context "eligible for both" do
      before do
        navigate_to_year_selection(lup_and_ecp_school)
      end

      scenario "do not teach ECP nor LUP subjects" do
        select_itt_year(AcademicYear.new(2020))

        choose "Mathematics"
        click_on "Continue"

        choose "No"
        click_on "Continue"

        expect(page).to have_css("div#would_be_eligible_for_both_ecp_and_lup_except_for_insufficient_teaching")
      end
    end
  end

  context "degree" do
    before do
      navigate_to_year_selection(lup_and_ecp_school)
    end

    scenario "lack both ITT subject and degree" do
      select_itt_year(AcademicYear.new(2021))

      choose "None of the above"
      click_on "Continue"

      choose "No"
      click_on "Continue"

      expect(page).to have_css("div#lack_both_valid_itt_subject_and_degree")
    end
  end

  context "lack ITT in ECP subject" do
    before do
      navigate_to_year_selection(ecp_only_school)
    end

    scenario "none of the above" do
      select_itt_year(AcademicYear.new(2020))

      choose "None of the above"
      click_on "Continue"

      expect(page).to have_css("div#bad_itt_subject_for_ecp")
    end
  end

  context "ECP-only school lacking ITT in Mathematics" do
    before do
      navigate_to_year_selection(ecp_only_school)
    end

    scenario "2018 ITT" do
      select_itt_year(AcademicYear.new(2018))

      # subject
      choose "No"
      click_on "Continue"

      expect(page).to have_css("div#bad_itt_year_for_ecp")
    end

    scenario "2019 ITT" do
      select_itt_year(AcademicYear.new(2019))

      # subject
      choose "No"
      click_on "Continue"

      expect(page).to have_css("div#bad_itt_year_for_ecp")
    end
  end

  context "trainee" do
    context "LUP school" do
      scenario "no training for LUP ITT nor have degree" do
        choose_school(lup_and_ecp_school)

        choose "No"
        click_on "Continue"

        choose "None of the above"
        click_on "Continue"

        choose "No"
        click_on "Continue"

        expect(page).to have_css("div#trainee_teaching_lacking_both_valid_itt_subject_and_degree")
      end
    end

    scenario "ECP-only school" do
      choose_school(ecp_only_school)

      choose "No"
      click_on "Continue"

      expect(page).to have_css("div#ecp_only_trainee_teacher")
    end
  end

  context "ECP-only school and no ECP subjects and nothing which can be eligible next year" do
    before do
      navigate_to_year_selection(ecp_only_school)
    end

    scenario "2017 ITT" do
      select_itt_year(AcademicYear.new(2017))

      expect(page).to have_css("div#no_ecp_subjects_that_itt_year")
    end

    scenario "2021 ITT" do
      select_itt_year(AcademicYear.new(2021))

      expect(page).to have_css("div#no_ecp_subjects_that_itt_year")
    end
  end

  context "school ineligible for both ECP and LUP" do
    scenario "primary school" do
      choose_school(primary_school)

      expect(page).to have_css("div#current_school")
    end
  end

  private

  def navigate_to_supply_teacher_subquestions
    choose_school lup_and_ecp_school
    click_on "Continue"

    # - Have you started your first year as a newly qualified teacher?
    choose "Yes"
    click_on "Continue"

    # - Are you currently employed as a supply teacher
    choose "Yes"
    click_on "Continue"
  end

  def navigate_to_performance_questions
    choose_school lup_and_ecp_school
    click_on "Continue"

    # - Have you started your first year as a newly qualified teacher?
    choose "Yes"
    click_on "Continue"

    # - Are you currently employed as a supply teacher
    choose "No"
    click_on "Continue"
  end

  def navigate_to_year_selection(school)
    # - Which school do you teach at
    choose_school school
    click_on "Continue"

    # - Have you started your first year as a newly qualified teacher?
    choose "Yes"
    click_on "Continue"

    # - Are you currently employed as a supply teacher
    choose "No"
    click_on "Continue"

    # - Poor performance
    choose "claim_eligibility_attributes_subject_to_formal_performance_action_false"
    choose "claim_eligibility_attributes_subject_to_disciplinary_action_false"
    click_on "Continue"

    # - What route into teaching did you take?
    expect(page).to have_text(I18n.t("early_career_payments.questions.qualification.heading"))

    choose "Undergraduate initial teacher training (ITT)"

    click_on "Continue"
  end

  def select_itt_year(year)
    year_string = "#{year.start_year} to #{year.end_year}"
    choose year_string
    click_on "Continue"
  end

  def select_subject(subject_string)
    choose subject_string
    click_on "Continue"
  end
end
