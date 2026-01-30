class SettingsController < ApplicationController
  def index
    redirect_to settings_contexts_path
  end
end
