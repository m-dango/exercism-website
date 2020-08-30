require 'test_helper'

class API::SolutionSerializerTest < ActiveSupport::TestCase
  test "basic to_hash" do
    solution = create :concept_solution
    create :user_track, user: solution.user, track: solution.track
    serializer = API::SolutionSerializer.new(solution, solution.user)
    expected = {
      solution: {
        id: solution.uuid,
        url: "https://test.exercism.io/tracks/ruby/exercises/bob",
        user: {
          handle: solution.user.handle,
          is_requester: true
        },
        exercise: {
          id: solution.exercise.slug,
          instructions_url: "https://test.exercism.io/tracks/ruby/exercises/bob",
          track: {
            id: solution.track.slug,
            language: solution.track.title
          }
        },
        file_download_base_url: "https://api.exercism.io/v1/solutions/#{solution.uuid}/files/",
        files: Set.new([".meta/config.json", "README.md", "bob.rb", "bob_test.rb", "subdir/more_bob.rb"]),
        iteration: nil
      }
    }

    assert_equal expected, serializer.to_hash
  end

  test "ignore iteration files that match ignore_regexp" do
    solution = create :concept_solution
    create :user_track, user: solution.user, track: solution.track

    # Check we've got a valid fixture for this test still
    # Without this we could silently invalidate this tes
    filepath = 'ignore.rb'
    Git::Exercise.for_solution(solution).filepaths.include?(filepath)
    assert filepath =~ solution.track.repo.ignore_regexp

    serializer = API::SolutionSerializer.new(solution, solution.user)
    refute_includes serializer.to_hash[:solution][:files], filepath
  end

  test "includes all solution files" do
    solution = create :concept_solution
    track = solution.track
    create :user_track, user: solution.user, track: track

    iteration = create :iteration, solution: solution
    valid_filepath = "foobar.js"
    ignore_filepath = "ignore.rb"
    create :iteration_file, iteration: iteration, filename: valid_filepath
    create :iteration_file, iteration: iteration, filename: ignore_filepath

    # Ensure that changing our fixture doesn't break this test
    refute valid_filepath =~ track.repo.ignore_regexp
    assert ignore_filepath =~ track.repo.ignore_regexp

    serializer = API::SolutionSerializer.new(solution, solution.user)
    assert_includes serializer.to_hash[:solution][:files], valid_filepath
    assert_includes serializer.to_hash[:solution][:files], ignore_filepath
  end

  test "to_hash with different requester" do
    user = create :user
    solution = create :concept_solution
    create :user_track, user: solution.user, track: solution.track

    serializer = API::SolutionSerializer.new(solution, user)
    refute serializer.to_hash[:solution][:user][:is_requester]
  end

  test "handle is alias when anonymous" do
    solution = create :concept_solution
    create :user_track, anonymous_during_mentoring: true, user: solution.user, track: solution.track

    serializer = API::SolutionSerializer.new(solution, solution.user)
    assert_equal solution.anonymised_user_handle, serializer.to_hash[:solution][:user][:handle]
  end

  test "iteration is represented correctly" do
    solution = create :concept_solution
    create :user_track, user: solution.user, track: solution.track
    serializer = API::SolutionSerializer.new(solution, solution.user)

    created_at = Time.current.getutc - 1.week
    create :iteration, solution: solution, created_at: created_at
    assert_equal created_at.to_i, serializer.to_hash[:solution][:iteration][:submitted_at].to_i
  end

  test "solution_url should be /mentoring/solutions if not user" do
    solution = create :concept_solution
    create :user_track, user: solution.user, track: solution.track
    mentor = create :user
    serializer = API::SolutionSerializer.new(solution, mentor)

    assert_equal "https://test.exercism.io/mentoring/solutions/#{solution.mentor_uuid}",
                 serializer.to_hash[:solution][:url]
  end
end
