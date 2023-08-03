class Track::Trophies::Shared::CompletedFiveHardExercisesTrophy < Track::Trophy
  def self.valid_track_slugs
    exercise_sql = Arel.sql(
      Exercise.where('difficulty >= 8').
        where('tracks.id = track_id').
        having("count(*) >= 5").
        select('1').
        to_sql
    )
    Track.active.where("EXISTS (#{exercise_sql})").pluck(:slug)
  end

  def name(_) = "Difficult"
  def icon = 'trophy-completed-five-hard-exercises'

  def criteria(track)
    "Awarded once you complete %<num_exercises>i hard exercises in %<track_title>s" % {
      num_exercises: NUM_EXERCISES,
      track_title: track
    }
  end

  def success_message(track)
    "Congratulations on completing %<num_exercises>i hard exercises in %<track_title>s" % {
      num_exercises: NUM_EXERCISES,
      track_title: track
    }
  end

  def award?(user_track) = user_track.completed?

  NUM_EXERCISES = 5
  private_constant :NUM_EXERCISES
end
