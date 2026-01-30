module Settings
  class InboxRulesController < ApplicationController
    before_action :set_inbox_rule, only: [:edit, :update, :destroy]

    def index
      @inbox_rules = InboxRule.includes(:dossier).ordered
      @new_rule = InboxRule.new
    end

    def create
      @inbox_rule = InboxRule.new(inbox_rule_params)

      if @inbox_rule.save
        apply_to_inbox! if params[:apply_to_inbox] == "1"
        redirect_to settings_inbox_rules_path, notice: "Regel toegevoegd"
      else
        @inbox_rules = InboxRule.includes(:dossier).ordered
        @new_rule = @inbox_rule
        render :index, status: :unprocessable_entity
      end
    end

    def edit
    end

    def update
      if @inbox_rule.update(inbox_rule_params)
        apply_to_inbox! if params[:apply_to_inbox] == "1"
        redirect_to settings_inbox_rules_path, notice: "Regel bijgewerkt"
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      @inbox_rule.destroy!
      redirect_to settings_inbox_rules_path, notice: "Regel verwijderd"
    end

    private

    def set_inbox_rule
      @inbox_rule = InboxRule.find(params[:id])
    end

    def inbox_rule_params
      params.require(:inbox_rule).permit(:term, :dossier_id)
    end

    def apply_to_inbox!
      ActionItem.inbox.pending.find_each do |item|
        if @inbox_rule.matches?(item.description)
          item.update!(dossier: @inbox_rule.dossier)
        end
      end
    end
  end
end
