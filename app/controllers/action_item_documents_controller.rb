class ActionItemDocumentsController < ApplicationController
  before_action :set_action_item

  def create
    if params[:document_id].present?
      # Link existing document
      @document = Document.find(params[:document_id])
      @action_item.action_item_documents.find_or_create_by(document: @document)
    elsif params[:document].present?
      # Upload new document
      @document = @action_item.dossier.documents.build(document_params)
      @document.save
      @action_item.documents << @document if @document.persisted?
    end

    load_recent_documents

    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to @action_item, notice: "Document gekoppeld" }
      format.json { head :ok }
    end
  end

  def destroy
    @document = @action_item.documents.find(params[:id])
    @action_item.action_item_documents.find_by(document: @document)&.destroy

    load_recent_documents

    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to @action_item, notice: "Document ontkoppeld" }
      format.json { head :ok }
    end
  end

  private

  def set_action_item
    @action_item = ActionItem.find(params[:action_item_id])
  end

  def document_params
    params.require(:document).permit(:name, :file, :occurred_at)
  end

  def load_recent_documents
    @action_item.reload
    @recent_documents = Document.where("created_at > ?", 24.hours.ago)
                                .where.not(id: @action_item.document_ids)
                                .order(created_at: :desc)
                                .limit(10)
  end
end
