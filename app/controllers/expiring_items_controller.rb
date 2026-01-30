class ExpiringItemsController < ApplicationController
  before_action :set_expiring_item, only: [:edit, :update, :destroy]

  def index
    @expiring_items = ExpiringItem.ordered
    @expired = @expiring_items.expired
    @expiring_soon = @expiring_items.expiring_soon.where.not(id: @expired.pluck(:id))
    @valid = @expiring_items.active.where.not(id: @expiring_soon.pluck(:id))
  end

  def new
    @expiring_item = ExpiringItem.new
  end

  def create
    @expiring_item = ExpiringItem.new(expiring_item_params)

    if @expiring_item.save
      redirect_to expiring_items_path, notice: "Item toegevoegd"
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @expiring_item.update(expiring_item_params)
      redirect_to expiring_items_path, notice: "Item bijgewerkt"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @expiring_item.destroy!
    redirect_to expiring_items_path, notice: "Item verwijderd"
  end

  private

  def set_expiring_item
    @expiring_item = ExpiringItem.find(params[:id])
  end

  def expiring_item_params
    params.require(:expiring_item).permit(:name, :expires_at, :description, :notify_days_before)
  end
end
