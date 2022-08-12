require 'test_helper'

class SerializeExerciseRepresentationTest < ActiveSupport::TestCase
  test "serialize representation" do
    track = create :track, title: 'Ruby'
    exercise = create :practice_exercise, title: 'Bob', track: track
    representation = create :exercise_representation, feedback_markdown: 'Yay', exercise: exercise, num_submissions: 5

    expected = {
      exercise: {
        icon_url: 'https://exercism-v3-icons.s3.eu-west-2.amazonaws.com/exercises/bob.svg',
        title: 'Bob'
      },
      track: {
        icon_url: 'https://exercism-v3-icons.s3.eu-west-2.amazonaws.com/tracks/ruby.svg',
        title: 'Ruby'
      },
      num_submissions: 5,
      feedback_html: "<p>Yay</p>\n",
      links: {}
    }

    assert_equal expected, SerializeExerciseRepresentation.(representation)
  end
end
