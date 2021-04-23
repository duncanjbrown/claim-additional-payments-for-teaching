FactoryBot.define do
  factory :early_career_payments_eligibility, class: "EarlyCareerPayments::Eligibility" do
    trait :eligible do
      nqt_in_academic_year_after_itt { true }
      employed_as_supply_teacher { false }
      subject_to_disciplinary_action { false }
      pgitt_or_ugitt_course { :postgraduate }
      eligible_itt_subject { 2 }
      teaching_subject_now { true }
    end
  end
end
