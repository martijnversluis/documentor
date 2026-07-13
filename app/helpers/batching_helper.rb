module BatchingHelper
  # Minimum items needed to suggest a batch
  MIN_BATCH_SIZE = 3

  # Maximum time for a batch suggestion (in minutes)
  MAX_BATCH_TIME = 60

  def batching_suggestions(action_items)
    materialized = action_items.to_a
    return [] if materialized.empty?

    cache_key = [
      "batching_suggestions/v1",
      materialized.size,
      materialized.map(&:id).sort.hash,
      materialized.map { |i| i.updated_at.to_i }.max
    ].join("/")

    Rails.cache.fetch(cache_key, expires_in: 5.minutes) do
      build_batching_suggestions(materialized)
    end
  end

  def build_batching_suggestions(action_items)
    suggestions = []

    context_batches = Hash.new { |h, k| h[k] = [] }
    dossier_batches = Hash.new { |h, k| h[k] = [] }
    quick_items = []

    action_items.each do |item|
      context_batches[item.context] << item if item.context.present?
      dossier_batches[item.dossier] << item if item.dossier.present?
      quick_items << item if item.estimated_minutes.present? && item.estimated_minutes <= 15
    end

    context_batches.each do |context, items|
      next if items.size < MIN_BATCH_SIZE

      suggestions << {
        type: :context,
        title: "#{items.size} taken met context @#{context}",
        description: "Deze taken kun je samen doen omdat ze dezelfde context hebben",
        items: items,
        total_time: items.sum { |i| i.estimated_minutes || 15 },
        icon: "location"
      }
    end

    if quick_items.size >= MIN_BATCH_SIZE
      total_time = quick_items.sum(&:estimated_minutes)
      if total_time <= MAX_BATCH_TIME
        suggestions << {
          type: :quick,
          title: "#{quick_items.size} snelle taken",
          description: "Doe deze korte taken achter elkaar in #{total_time} minuten",
          items: quick_items,
          total_time: total_time,
          icon: "lightning"
        }
      end
    end

    dossier_batches.each do |dossier, items|
      next if items.size < MIN_BATCH_SIZE

      suggestions << {
        type: :dossier,
        title: "#{items.size} taken voor #{dossier.name}",
        description: "Focus op dit project en werk deze taken achter elkaar af",
        items: items,
        total_time: items.sum { |i| i.estimated_minutes || 15 },
        icon: "folder"
      }
    end

    suggestions.sort_by { |s| -s[:items].size }
  end

  def batch_icon(icon_name)
    case icon_name
    when "location"
      content_tag(:svg, class: "w-5 h-5", fill: "none", stroke: "currentColor", viewBox: "0 0 24 24") do
        content_tag(:path, nil, "stroke-linecap": "round", "stroke-linejoin": "round", "stroke-width": "2", d: "M17.657 16.657L13.414 20.9a1.998 1.998 0 01-2.827 0l-4.244-4.243a8 8 0 1111.314 0z")
      end
    when "lightning"
      content_tag(:svg, class: "w-5 h-5", fill: "none", stroke: "currentColor", viewBox: "0 0 24 24") do
        content_tag(:path, nil, "stroke-linecap": "round", "stroke-linejoin": "round", "stroke-width": "2", d: "M13 10V3L4 14h7v7l9-11h-7z")
      end
    when "folder"
      content_tag(:svg, class: "w-5 h-5", fill: "none", stroke: "currentColor", viewBox: "0 0 24 24") do
        content_tag(:path, nil, "stroke-linecap": "round", "stroke-linejoin": "round", "stroke-width": "2", d: "M3 7v10a2 2 0 002 2h14a2 2 0 002-2V9a2 2 0 00-2-2h-6l-2-2H5a2 2 0 00-2 2z")
      end
    end
  end

  def format_batch_time(minutes)
    if minutes >= 60
      hours = minutes / 60
      mins = minutes % 60
      mins > 0 ? "#{hours}u #{mins}min" : "#{hours} uur"
    else
      "#{minutes} min"
    end
  end
end
