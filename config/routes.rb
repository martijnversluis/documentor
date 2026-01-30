Rails.application.routes.draw do
  root "action_items#index"

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

  resources :checklists do
    member do
      get :use
      post :apply
    end
  end

  resources :expiring_items, except: [:show]

  resources :action_items, only: [:index, :show, :edit, :update, :destroy, :create] do
    collection do
      patch :reorder
      patch :postpone_today
      get :power_through
      get :next_week
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
      end
    end
  end

  resources :review_templates

  # Habits
  resources :habits do
    member do
      post :toggle
      post :increment
      post :decrement
    end
  end

  # Work mode toggle
  patch "work_mode", to: "work_mode#toggle", as: :toggle_work_mode

  # GitHub dashboard
  get "github/dashboard", to: "github#dashboard", as: :github_dashboard

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
      end
    end
  end

  # Health check
  get "up" => "rails/health#show", as: :rails_health_check
end
