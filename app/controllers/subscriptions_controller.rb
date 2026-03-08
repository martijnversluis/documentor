class SubscriptionsController < ApplicationController
  before_action :set_subscription, only: [:show, :edit, :update, :destroy, :archive, :unarchive]

  def index
    @subscriptions = Subscription.not_archived.includes(:parties).ordered
  end

  def archived
    @subscriptions = Subscription.archived.order(archived_at: :desc)
  end

  def show
  end

  def new
    @subscription = Subscription.new
  end

  def create
    @subscription = Subscription.new(subscription_params)

    if @subscription.save
      link_party
      redirect_to @subscription, notice: "Abonnement aangemaakt"
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @subscription.update(subscription_params)
      link_party
      redirect_to @subscription, notice: "Abonnement bijgewerkt"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @subscription.destroy
    redirect_to subscriptions_path, notice: "Abonnement verwijderd"
  end

  def archive
    @subscription.archive!
    redirect_to subscriptions_path, notice: "Abonnement gearchiveerd"
  end

  def unarchive
    @subscription.unarchive!
    redirect_to @subscription, notice: "Abonnement hersteld uit archief"
  end

  private

  def set_subscription
    @subscription = Subscription.find(params[:id])
  end

  def link_party
    @subscription.party_links.destroy_all
    if params[:party_id].present?
      party = Party.find(params[:party_id])
      @subscription.party_links.find_or_create_by(party: party)
    end
  end

  def subscription_params
    params.require(:subscription).permit(
      :name, :description, :reference, :starts_on, :ends_on, :auto_renew,
      :cost, :cost_frequency, :contract_duration, :portal_url,
      :dossier_id, :tag_list
    )
  end
end
