require "rails_helper"

RSpec.feature "Ineligible Teacher Early Career Payments claims" do
  scenario "NQT not in Academic Year after ITT" do
    visit landing_page_path(EarlyCareerPayments.routing_name)
    expect(page).to have_link(href: EarlyCareerPayments.feedback_url)

    # Landing (start)
    expect(page).to have_text(I18n.t("early_career_payments.landing_page"))
    click_on "Start Now"

    # NQT in Academic Year after ITT
    expect(page).to have_text(I18n.t("early_career_payments.questions.nqt_in_academic_year_after_itt"))

    choose "No"
    click_on "Continue"

    claim = Claim.order(:created_at).last
    eligibility = claim.eligibility

    expect(eligibility.nqt_in_academic_year_after_itt).to eql false

    expect(page).to have_text(I18n.t("early_career_payments.ineligible"))
    expect(page).to have_link(href: EarlyCareerPayments.eligibility_page_url)
    expect(page).to have_text("Based on the answers you have provided you are not eligible #{I18n.t("early_career_payments.claim_description")}")
  end

  # Additional sad paths
  # TODO [PAGE 17] - This school is not eligible (sad path)
  # TODO [PAGE 19] - You will be eligible for an early career payment in 2022
end
