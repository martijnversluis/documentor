class PartyLinksController < ApplicationController
  before_action :set_linkable

  def create
    if params[:new_party_name].present?
      @party = Party.create!(name: params[:new_party_name])
    else
      @party = Party.find(params[:party_id])
    end
    @party_link = @linkable.party_links.find_or_create_by(party: @party)

    respond_to do |format|
      format.turbo_stream
      format.html { redirect_back fallback_location: @linkable }
    end
  end

  def destroy
    @party_link = @linkable.party_links.find(params[:id])
    @party = @party_link.party
    @party_link.destroy

    respond_to do |format|
      format.turbo_stream
      format.html { redirect_back fallback_location: @linkable }
    end
  end

  private

  def set_linkable
    if params[:dossier_id]
      @linkable = Dossier.find(params[:dossier_id])
    elsif params[:document_id]
      @linkable = Document.find(params[:document_id])
    elsif params[:note_id]
      @linkable = Note.find(params[:note_id])
    elsif params[:folder_id]
      @linkable = Folder.find(params[:folder_id])
    end
  end
end
