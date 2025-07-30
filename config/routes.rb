Rails.application.routes.draw do
  # Root page shows the simulator form
  root to: 'pages#simulator'

  # Display the form
  get 'simulator', to: 'pages#simulator', as: :simulator

  # Handle form submission
  post 'simulator/calculate', to: 'pages#calculate', as: :simulator_calculate

  get 'simulator/calculate', to: redirect('/simulator')

  get "up" => "rails/health#show", as: :rails_health_check
end