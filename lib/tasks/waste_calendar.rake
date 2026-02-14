namespace :waste_calendar do
  desc "Import waste calendar from ICS file"
  task :import_ics, [:file_path] => :environment do |_t, args|
    file_path = args[:file_path]

    unless file_path && File.exist?(file_path)
      puts "Usage: rails waste_calendar:import_ics[path/to/calendar.ics]"
      exit 1
    end

    content = File.read(file_path)
    count = SyncWasteCalendarJob.sync_from_ics(content)

    puts "Imported #{count} waste pickup dates"
  end

  desc "Add a single waste pickup manually"
  task :add, [:date, :waste_type] => :environment do |_t, args|
    date = Date.parse(args[:date])
    waste_type = args[:waste_type].upcase

    pickup = WastePickup.create!(collection_date: date, waste_type: waste_type)
    puts "Added #{waste_type} pickup for #{date}"
  rescue Date::Error
    puts "Invalid date format. Use YYYY-MM-DD"
    exit 1
  rescue ActiveRecord::RecordInvalid => e
    puts "Error: #{e.message}"
    exit 1
  end

  desc "List upcoming waste pickups"
  task list: :environment do
    pickups = WastePickup.upcoming.limit(20)

    if pickups.empty?
      puts "No upcoming waste pickups scheduled"
    else
      pickups.each do |pickup|
        puts "#{pickup.collection_date.strftime('%a %d %b %Y')}: #{pickup.waste_type}"
      end
    end
  end

  desc "Sync waste calendar from configured provider"
  task sync: :environment do
    SyncWasteCalendarJob.perform_now
    puts "Sync complete. #{WastePickup.upcoming.count} upcoming pickups."
  end

  desc "Clear all waste pickups"
  task clear: :environment do
    count = WastePickup.delete_all
    puts "Deleted #{count} waste pickups"
  end
end
