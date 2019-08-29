require "rails_helper"

RSpec.describe ClaimMailer, type: :mailer do
  describe "#submitted" do
    let(:claim) { create(:claim, :submittable, first_name: "Abraham", surname: "Lincoln") }
    let(:mail) { ClaimMailer.submitted(claim) }

    it "renders the headers" do
      expect(mail.subject).to eq("Your claim was received")
      expect(mail.to).to eq([claim.email_address])
    end

    it "renders the body" do
      expect(mail.body.encoded).to match("Dear Abraham Lincoln,")
      expect(mail.body.encoded).to match("We've received your application to claim back your student loan repayments for the time you spent at #{claim.eligibility.claim_school.name}.")
      expect(mail.body.encoded).to match("Your unique reference is #{claim.reference}. You will need this if you contact us about your claim.")
    end
  end
end
