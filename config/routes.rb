Rails.application.routes.draw do
  resource :session
  resource :turn_credentials, only: [ :show ]
  resources :passwords, param: :token
  resources :invites, only: [ :index, :new, :create, :show, :update, :destroy ], param: :token
  resources :contacts, only: [ :index, :destroy ]
  resources :calls, only: [ :index, :create, :show ] do
    resource :answer, only: [ :create ], controller: "call/answers"
    resource :decline, only: [ :create ], controller: "call/declines"
    resource :hangup, only: [ :create ], controller: "call/hangups"
  end

  mount MissionControl::Jobs::Engine, at: "/jobs" if defined?(MissionControl::Jobs::Engine)
  mount LetterOpenerWeb::Engine, at: "/letter_opener" if Rails.env.development?

  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  root "contacts#index"
end
