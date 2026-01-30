class AddCiUniquenessIndexToParties < ActiveRecord::Migration[8.0]
  def up
    # First, merge duplicate parties (case-insensitive)
    duplicates = execute(<<-SQL).to_a
      SELECT LOWER(TRIM(name)) as lower_name, array_agg(id ORDER BY id) as ids
      FROM parties
      GROUP BY LOWER(TRIM(name))
      HAVING COUNT(*) > 1
    SQL

    duplicates.each do |row|
      ids = row["ids"][1..-2].split(",").map(&:to_i) # Parse PostgreSQL array
      keep_id = ids.first
      duplicate_ids = ids[1..]

      # Move all party_links to the party we're keeping
      execute("UPDATE party_links SET party_id = #{keep_id} WHERE party_id IN (#{duplicate_ids.join(',')})")

      # Delete the duplicate parties
      execute("DELETE FROM parties WHERE id IN (#{duplicate_ids.join(',')})")
    end

    # Normalize all names (strip whitespace)
    execute("UPDATE parties SET name = TRIM(name)")

    # Add unique index
    add_index :parties, "LOWER(name)", unique: true, name: "index_parties_on_lower_name"
  end

  def down
    remove_index :parties, name: "index_parties_on_lower_name"
  end
end
