class SessionsController < ApplicationController
  skip_before_action :require_login, only: [:new, :create]
  layout false

  def new
    redirect_to root_path if session[:authenticated]
  end

  def create
    if params[:username] == ENV["AUTH_USERNAME"] && params[:password] == ENV["AUTH_PASSWORD"]
      session[:authenticated] = true
      redirect_to session.delete(:return_to) || root_path
    else
      flash.now[:alert] = "Ongeldige gebruikersnaam of wachtwoord"
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    reset_session
    redirect_to login_path
  end
end
