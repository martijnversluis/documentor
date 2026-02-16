Rails.application.routes.draw do
  root "action_items#today"

  # API for Chrome extension
  namespace :api do
    resources :dossiers, only: [:index] do
      resources :folders, only: [:index]
    end
    resources :documents, only: [:create]
    resources :notes, only: [:create]
    resources :action_items, only: [:create]
  end

  get "inbox", to: "inbox#index", as: :inbox
  scope :inbox, as: :inbox do
    resources :documents, only: [:new, :create], controller: "inbox/documents"
    resources :notes, only: [:new, :create], controller: "inbox/notes"
    resources :action_items, only: [:create], controller: "inbox/action_items"
  end

  resources :dossiers do
    collection do
      get :archived
    end
    member do
      patch :archive
      patch :unarchive
      patch :merge_into
    end
    resources :folders, shallow: true
    resources :documents, shallow: true
    resources :notes, shallow: true
    resources :action_items, only: [:create], shallow: true
    resources :party_links, only: [:create, :destroy]
  end

  resources :folders do
    member do
      get :download
    end
    resources :documents, shallow: true
    resources :notes, shallow: true
    resources :party_links, only: [:create, :destroy]
  end

  resources :documents, only: [:show, :edit, :update, :destroy] do
    member do
      patch :move
      patch :assign
      get :download
    end
    resources :party_links, only: [:create, :destroy]
  end

  resources :notes, only: [:show, :edit, :update, :destroy] do
    member do
      patch :move
      patch :assign
    end
    resources :party_links, only: [:create, :destroy]
  end

  resources :tags do
    member do
      get :items
    end
  end

  resources :parties

  resources :dossier_templates do
    member do
      get :use
      post :apply
    end
  end

  resources :checklists, except: [:destroy] do
    member do
      get :use
      post :apply
      patch :archive
      patch :unarchive
    end
  end

  resources :expiring_items, except: [:show]

  resources :action_items, only: [:show, :edit, :update, :destroy, :create] do
    collection do
      get :today
      get :tomorrow
      get :yesterday
      get :overdue
      get :waiting
      get :someday
      get :next_actions
      get :quick_wins
      get :recurring
      get :inbox, as: :filter_inbox
      scope :week do
        get :current, action: :week
        get :next, action: :week
        get :previous, action: :week
        get ":number", action: :week, as: :number, constraints: { number: /\d+/ }
      end
      get :power_through
      patch :reorder
      patch :postpone_today
    end
    member do
      patch :toggle
      patch :assign
      patch :update_completion_notes
      patch :update_notes
      post :extract_notes
    end
    resources :documents, only: [:create, :destroy], controller: "action_item_documents"
  end

  get "search", to: "search#index"
  get "search/quick", to: "search#quick"
  get "review", to: "review#index", as: :review_helper

  # GTD Reviews
  get "reviews/next", to: "reviews#next_review", as: :next_review
  resources :reviews, except: [:new, :edit, :update] do
    member do
      post :start
      patch :pause
      patch :resume
    end
    resources :review_steps, only: [:show, :update] do
      member do
        patch :complete
        patch :skip
        patch :toggle_checkbox
      end
    end
  end

  resources :review_templates, except: [:destroy] do
    member do
      patch :archive
      patch :unarchive
    end
  end

  # Habits
  resources :habits, except: [:destroy] do
    member do
      post :toggle
      post :increment
      post :decrement
      patch :archive
      patch :unarchive
    end
  end

  # Work mode toggle
  patch "work_mode", to: "work_mode#toggle", as: :toggle_work_mode

  # GitHub dashboard
  get "github/dashboard", to: "github#dashboard", as: :github_dashboard
  post "github/promote", to: "github#promote", as: :github_promote

  # Mail dashboard
  get "mail/dashboard", to: "mail#dashboard", as: :mail_dashboard
  post "mail/promote", to: "mail#promote", as: :mail_promote
  post "mail/dismiss", to: "mail#dismiss", as: :mail_dismiss

  # Meetings
  get "meetings/banner", to: "meetings#banner", as: :meetings_banner
  get "meetings/next", to: "meetings#next_meeting", as: :next_meeting
  post "meetings/enter", to: "meetings#enter", as: :enter_meeting
  resources :meetings, only: [:index, :show, :update] do
    resources :action_items, only: [:create], controller: "meeting_action_items"
  end

  # Settings
  get "settings", to: "settings#index", as: :settings
  namespace :settings do
    resources :contexts, except: [:show, :new] do
      collection do
        patch :reorder
      end
    end
    resources :inbox_rules, except: [:show, :new]
    resources :google_accounts, only: [:index, :create, :destroy] do
      collection do
        get :callback
      end
      member do
        patch :toggle_mail
      end
      resources :google_calendars, only: [:index, :update]
    end
    resources :github_accounts, only: [:index, :create, :destroy] do
      collection do
        get :callback
      end
    end
    resources :waste_calendar, only: [:index] do
      collection do
        patch :update
        post :test
        post :sync
        post :create_pickup
        post :import_ics
      end
      member do
        delete :destroy_pickup
      end
    end
    resources :configuration, only: [:index] do
      collection do
        patch :update
      end
    end
  end

  # Health check
  get "up" => "rails/health#show", as: :rails_health_check

  # Job queue dashboard
  mount MissionControl::Jobs::Engine, at: "/jobs"
end
