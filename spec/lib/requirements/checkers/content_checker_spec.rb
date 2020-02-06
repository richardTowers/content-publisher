# frozen_string_literal: true

RSpec.describe Requirements::Checkers::ContentChecker do
  describe "#pre_preview_issues" do
    it "returns no issues if there are none" do
      edition = build :edition
      issues = Requirements::Checkers::ContentChecker.new(edition).pre_preview_issues
      expect(issues).to be_empty
    end

    it "delegates to return issues with content fields" do
      issues = Requirements::CheckerIssues.new(%w(issue))
      body_field = double(:body_field, pre_preview_issues: issues)
      document_type = build :document_type, contents: [body_field]
      edition = build :edition, document_type: document_type
      issues = Requirements::Checkers::ContentChecker.new(edition).pre_preview_issues
      expect(issues).to eq issues
    end
  end

  describe "#pre_publish_issues" do
    it "returns no issues if there are none" do
      edition = build :edition, :publishable
      issues = Requirements::Checkers::ContentChecker.new(edition).pre_publish_issues
      expect(issues).to be_empty
    end

    it "delegates to return issues with content fields" do
      issues = Requirements::CheckerIssues.new(%w(issue))
      body_field = double(:body_field, pre_publish_issues: issues)
      document_type = build :document_type, contents: [body_field]
      edition = build :edition, document_type: document_type
      issues = Requirements::Checkers::ContentChecker.new(edition).pre_publish_issues
      expect(issues).to eq issues
    end

    it "returns an issue if a major change note is blank" do
      document = build :document, :with_live_edition
      edition = build :edition, update_type: "major", change_note: nil, document: document
      issues = Requirements::Checkers::ContentChecker.new(edition).pre_publish_issues
      expect(issues).to have_issue(:change_note, :blank, styles: %i[form summary])
    end
  end
end