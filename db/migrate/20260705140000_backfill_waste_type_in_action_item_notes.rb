class BackfillWasteTypeInActionItemNotes < ActiveRecord::Migration[8.0]
  def up
    execute <<~SQL
      UPDATE action_items ai
      SET notes = 'waste_type:' || wp.waste_type || E'\nwaste_pickup:' || wp.id
      FROM waste_pickups wp
      WHERE ai.notes = 'waste_pickup:' || wp.id
    SQL
  end

  def down
    execute <<~SQL
      UPDATE action_items ai
      SET notes = 'waste_pickup:' || wp.id
      FROM waste_pickups wp
      WHERE ai.notes = 'waste_type:' || wp.waste_type || E'\nwaste_pickup:' || wp.id
    SQL
  end
end
