module BatchingHelper
  # Minimum items needed to suggest a batch
  MIN_BATCH_SIZE = 3

  # Maximum time for a batch suggestion (in minutes)
  MAX_BATCH_TIME = 60

  def batching_suggestions(action_items)
    suggestions = []

    # Group by context
    context_batches = action_items.group_by(&:context).reject { |ctx, _| ctx.blank? }
    context_batches.each do |context, items|
      next if items.size < MIN_BATCH_SIZE

      total_time = items.sum { |i| i.estimated_minutes || 15 }
      suggestions << {
        type: :context,
        title: "#{items.size} taken met context @#{context}",
        description: "Deze taken kun je samen doen omdat ze dezelfde context hebben",
        items: items,
        total_time: total_time,
        icon: "location"
      }
    end

    # Group quick tasks (≤15 min)
    quick_items = action_items.select { |i| i.estimated_minutes.present? && i.estimated_minutes <= 15 }
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

    # Group by dossier (if multiple items in same dossier)
    dossier_batches = action_items.select { |i| i.dossier.present? }.group_by(&:dossier)
    dossier_batches.each do |dossier, items|
      next if items.size < MIN_BATCH_SIZE

      total_time = items.sum { |i| i.estimated_minutes || 15 }
      suggestions << {
        type: :dossier,
        title: "#{items.size} taken voor #{dossier.name}",
        description: "Focus op dit project en werk deze taken achter elkaar af",
        items: items,
        total_time: total_time,
        icon: "folder"
      }
    end

    # Sort by batch size (most items first)
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
