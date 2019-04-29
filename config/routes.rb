Rails.application.routes.draw do
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
  get "start/index"
  root "claims#new"

  constraints slug: /qts_year|claim_school/ do
    resources :claims, only: [:new, :create, :show, :update], param: :slug
  end
end
