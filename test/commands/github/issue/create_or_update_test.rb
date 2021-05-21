require "test_helper"

class Github::Issue::CreateOrUpdateTest < ActiveSupport::TestCase
  test "create issue with labels" do
    issue = Github::Issue::CreateOrUpdate.(
      "MDU6SXNzdWU3MjM2MjUwMTI=",
      number: 999,
      title: "grep is failing on Windows",
      state: "OPEN",
      repo: "exercism/ruby",
      labels: %w[bug good-first-issue],
      opened_at: Time.parse("2020-10-17T02:39:37Z").utc,
      opened_by_username: "SleeplessByte"
    )

    assert_equal "MDU6SXNzdWU3MjM2MjUwMTI=", issue.node_id
    assert_equal 999, issue.number
    assert_equal "grep is failing on Windows", issue.title
    assert_equal "exercism/ruby", issue.repo
    assert_equal :open, issue.status
    assert_equal %w[bug good-first-issue], issue.labels.pluck(:label).sort
    assert_equal Time.parse("2020-10-17T02:39:37Z").utc, issue.opened_at
    assert_equal "SleeplessByte", issue.opened_by_username
  end

  test "create issue without labels" do
    issue = Github::Issue::CreateOrUpdate.(
      "MDU6SXNzdWU3MjM2MjUwMTI=",
      number: 999,
      title: "grep is failing on Windows",
      state: "OPEN",
      repo: "exercism/ruby",
      labels: [],
      opened_at: Time.parse("2020-10-17T02:39:37Z").utc,
      opened_by_username: "SleeplessByte"
    )

    assert_equal "MDU6SXNzdWU3MjM2MjUwMTI=", issue.node_id
    assert_equal 999, issue.number
    assert_equal "grep is failing on Windows", issue.title
    assert_equal "exercism/ruby", issue.repo
    assert_equal :open, issue.status
    assert_empty issue.labels
    assert_equal Time.parse("2020-10-17T02:39:37Z").utc, issue.opened_at
    assert_equal "SleeplessByte", issue.opened_by_username
  end

  test "create issue without author" do
    issue = Github::Issue::CreateOrUpdate.(
      "MDU6SXNzdWU3MjM2MjUwMTI=",
      number: 999,
      title: "grep is failing on Windows",
      state: "OPEN",
      repo: "exercism/ruby",
      labels: [],
      opened_at: Time.parse("2020-10-17T02:39:37Z").utc,
      opened_by_username: nil
    )

    assert_equal "MDU6SXNzdWU3MjM2MjUwMTI=", issue.node_id
    assert_equal 999, issue.number
    assert_equal "grep is failing on Windows", issue.title
    assert_equal "exercism/ruby", issue.repo
    assert_equal :open, issue.status
    assert_empty issue.labels
    assert_equal Time.parse("2020-10-17T02:39:37Z").utc, issue.opened_at
    assert issue.opened_by_username.nil?
  end

  test "update issue if data has changed" do
    issue = create :github_issue

    Github::Issue::CreateOrUpdate.(
      issue.node_id,
      number: issue.number,
      title: "grep is unsuccessful on Windows",
      state: issue.status.to_s.upcase,
      repo: issue.repo,
      labels: %w[bug good-first-issue help-wanted],
      opened_at: issue.opened_at,
      opened_by_username: issue.opened_by_username
    )

    issue.reload
    assert_equal "grep is unsuccessful on Windows", issue.title
    assert_equal %w[bug good-first-issue help-wanted], issue.labels.pluck(:label).sort
  end

  test "does not update pull request if data has not changed" do
    freeze_time do
      issue = create :github_issue
      updated_at_before_call = issue.updated_at

      Github::Issue::CreateOrUpdate.(
        issue.node_id,
        number: issue.number,
        title: issue.title,
        state: issue.status.to_s.upcase,
        repo: issue.repo,
        labels: issue.labels.pluck(:label),
        opened_at: issue.opened_at,
        opened_by_username: issue.opened_by_username
      )

      assert_equal updated_at_before_call, issue.reload.updated_at
    end
  end

  test "removes labels if no longer present" do
    issue = create :github_issue
    create :github_issue_label, issue: issue

    Github::Issue::CreateOrUpdate.(
      issue.node_id,
      number: issue.number,
      title: issue.title,
      state: issue.status.to_s.upcase,
      repo: issue.repo,
      labels: [],
      opened_at: issue.opened_at,
      opened_by_username: issue.opened_by_username
    )

    assert_empty issue.reload.labels
  end
end