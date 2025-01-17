module RequestHelpers
  def start_student_loans_claim
    start_claim(StudentLoans.routing_name)
  end

  def start_claim(routing_name)
    post claims_path(routing_name)
  end

  def non_service_operator_roles
    [
      DfeSignIn::User::PAYROLL_OPERATOR_DFE_SIGN_IN_ROLE_CODE,
      DfeSignIn::User::SUPPORT_AGENT_DFE_SIGN_IN_ROLE_CODE
    ]
  end

  # Signs in as a user with the service operator role. Returns the signed-in User record.
  def sign_in_as_service_operator
    user = create(:dfe_signin_user)
    sign_in_to_admin_with_role(DfeSignIn::User::SERVICE_OPERATOR_DFE_SIGN_IN_ROLE_CODE, user.dfe_sign_in_id)
    user
  end

  def sign_in_to_admin_with_role(*args)
    stub_dfe_sign_in_with_role(*args)
    post admin_dfe_sign_in_path
    follow_redirect!
  end
end
