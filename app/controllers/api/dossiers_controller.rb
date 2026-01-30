module Api
  class DossiersController < BaseController
    def index
      query = params[:q]&.strip

      # Find best match if query provided
      matched = nil
      if query.present?
        # Exact match first, then starts with
        matched = Dossier.find_by("LOWER(name) = ?", query.downcase)
        matched ||= Dossier.where("LOWER(name) LIKE ?", "#{query.downcase}%").order(:name).first
      end

      # 3 most recently updated dossiers, sorted alphabetically
      recent = Dossier.order(updated_at: :desc).limit(3).sort_by(&:name)

      # All dossiers alphabetically
      all_dossiers = Dossier.order(:name)

      render json: {
        matched: matched ? dossier_json(matched) : nil,
        recent: recent.map { |d| dossier_json(d) },
        all: all_dossiers.map { |d| dossier_json(d) }
      }
    end

    private

    def dossier_json(dossier)
      {
        id: dossier.id,
        name: dossier.name
      }
    end
  end
end
