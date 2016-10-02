Rails.application.routes.draw do
  get 'auth0/callback'

  get 'auth0/failure'

  get 'dashboard/show'

  get 'public_pages/home'

  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
end
