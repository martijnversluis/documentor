desc "Copy Active Storage blobs from one service to another (FROM=local TO=hetzner)"
task "active_storage:copy" => :environment do
  from_name = ENV.fetch("FROM")
  to_name = ENV.fetch("TO")

  from_service = ActiveStorage::Blob.services.fetch(from_name.to_sym)
  to_service = ActiveStorage::Blob.services.fetch(to_name.to_sym)

  ActiveStorage::Blob.find_each do |blob|
    if from_service.exist?(blob.key)
      if to_service.exist?(blob.key)
        puts "Already exists: #{blob.key} (#{blob.filename})"
      else
        print "Copying: #{blob.key} (#{blob.filename})... "
        from_service.open(blob.key, checksum: blob.checksum) do |file|
          to_service.upload(blob.key, file, checksum: blob.checksum)
        end
        puts "done"
      end
    else
      puts "Missing in #{from_name}: #{blob.key} (#{blob.filename})"
    end
  end

  puts "Finished copying from #{from_name} to #{to_name}"
end
