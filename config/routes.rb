Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Cron-triggered deadline/announcement runner — see app/controllers/internal/scheduler_controller.rb
  namespace :internal do
    post "scheduler/run", to: "scheduler#run"
  end

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  get "signup" => "registrations#new"
  post "signup" => "registrations#create"

  get "login" => "sessions#new"
  post "login" => "sessions#create"
  delete "logout" => "sessions#destroy"

  get "join/:invite_code" => "invites#show", as: :join
  post "join/:invite_code" => "invites#create"

  resources :seasons, only: %i[new create show] do
    member do
      post :start
      post :merge
      post :start_jury_phase
      post :reveal_finale
    end

    resources :tribes, only: %i[create destroy]
    resources :season_memberships, only: %i[update] do
      member do
        post :remove
        post :reset_pin
      end
    end
    resource :jury_vote, only: %i[create]
    resources :idols, only: %i[create]

    resources :message_threads, only: %i[index show create] do
      resources :messages, only: %i[create]
    end

    resources :announcements, only: %i[index create]

    resources :rounds, only: %i[new create show] do
      member do
        post :open_challenge
        post :close_challenge
        post :finalize_results
        post :open_voting
        post :close_voting
        post :reveal_tribal_council
      end

      resource :challenge_submission, only: %i[update]
      resource :vote, only: %i[create]
      resource :idol_play, only: %i[create]
    end
  end

  root "home#index"
end
