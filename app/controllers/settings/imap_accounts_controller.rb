module Settings
  class ImapAccountsController < ApplicationController
    before_action :set_imap_account, only: [:edit, :update, :destroy, :toggle]

    def index
      @imap_accounts = ImapAccount.order(:label)
    end

    def new
      @imap_account = ImapAccount.new(
        label: "HEY",
        host: "imap.hey.com",
        port: 993,
        folder: "INBOX"
      )
    end

    def create
      @imap_account = ImapAccount.new(imap_account_params)
      if @imap_account.save
        redirect_to settings_imap_accounts_path, notice: "IMAP-account toegevoegd"
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit
    end

    def update
      attrs = imap_account_params
      attrs = attrs.except(:password) if attrs[:password].blank?

      if @imap_account.update(attrs)
        redirect_to settings_imap_accounts_path, notice: "IMAP-account bijgewerkt"
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      @imap_account.discard!
      redirect_to settings_imap_accounts_path, notice: "IMAP-account verwijderd"
    end

    def toggle
      @imap_account.update!(enabled: !@imap_account.enabled)
      redirect_to settings_imap_accounts_path
    end

    private

    def set_imap_account
      @imap_account = ImapAccount.find(params[:id])
    end

    def imap_account_params
      params.require(:imap_account).permit(:label, :host, :port, :username, :password, :folder, :enabled)
    end
  end
end
