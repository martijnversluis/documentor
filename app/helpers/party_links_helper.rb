module PartyLinksHelper
  def party_links_path(linkable)
    case linkable
    when Dossier
      dossier_party_links_path(linkable)
    when Document
      document_party_links_path(linkable)
    when Note
      note_party_links_path(linkable)
    when Folder
      folder_party_links_path(linkable)
    end
  end

  def party_link_path(linkable, party_link)
    case linkable
    when Dossier
      dossier_party_link_path(linkable, party_link)
    when Document
      document_party_link_path(linkable, party_link)
    when Note
      note_party_link_path(linkable, party_link)
    when Folder
      folder_party_link_path(linkable, party_link)
    end
  end
end
