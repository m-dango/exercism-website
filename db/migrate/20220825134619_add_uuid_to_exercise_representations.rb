class AddUuidToExerciseRepresentations < ActiveRecord::Migration[7.0]
  def change
    add_column :exercise_representations, :uuid, :string, null: true, index: { unique: true }, if_not_exists: true

    # TODO: consider if we can run this in production
    ActiveRecord::Base.transaction(isolation: Exercism::READ_COMMITTED) do
      Exercise::Representation.find_each do |representation|
        Exercise::Representation
          .where(id: representation.id)
          .update_all(uuid: SecureRandom.compact_uuid)
      end
    end

    change_column_null :exercise_representations, :uuid, false
  end
end