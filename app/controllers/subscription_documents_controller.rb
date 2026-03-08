class SubscriptionDocumentsController < ApplicationController
  before_action :set_subscription

  def create
    if params[:document_id].present?
      @document = Document.find(params[:document_id])
      @subscription.subscription_documents.find_or_create_by(document: @document)
    elsif params[:files].present?
      Array(params[:files]).each do |file|
        next unless file.is_a?(ActionDispatch::Http::UploadedFile)

        document = Document.create!(
          name: file.original_filename,
          file: file,
          dossier: @subscription.dossier
        )
        @subscription.subscription_documents.find_or_create_by(document: document)
      end
    end

    redirect_to @subscription, notice: "Document gekoppeld"
  end

  def destroy
    @document = @subscription.documents.find(params[:id])
    @subscription.subscription_documents.find_by(document: @document)&.destroy

    redirect_to @subscription, notice: "Document ontkoppeld"
  end

  private

  def set_subscription
    @subscription = Subscription.find(params[:subscription_id])
  end
end
