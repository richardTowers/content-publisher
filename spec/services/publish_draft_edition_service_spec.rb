RSpec.describe PublishDraftEditionService do
  describe ".call" do
    let(:user) { create(:user) }

    before do
      stub_any_publishing_api_publish
      populate_default_government_bulk_data
      allow(PreviewDraftEditionService).to receive(:call)
      allow(PublishAssetsService).to receive(:call)
    end

    context "when there is no live edition" do
      let(:edition) { create(:edition, :publishable) }

      it "publishes the current_edition" do
        publish_request = stub_publishing_api_publish(edition.content_id,
                                                      update_type: nil,
                                                      locale: edition.locale)

        described_class.call(edition, user, with_review: true)
        expect(publish_request).to have_been_requested
        expect(edition.document.live_edition).to eq(edition)
        expect(edition).to be_published
        expect(edition).to be_live
      end

      it "sets the document first publishing time" do
        freeze_time do
          expect { described_class.call(edition, user, with_review: true) }
            .to change(edition.document, :first_published_at).to(Time.zone.now)
        end
      end

      it "can specify if edition is reviewed" do
        described_class.call(edition, user, with_review: false)
        expect(edition).to be_published_but_needs_2i
      end
    end

    context "when there is a live edition" do
      let(:document) { create(:document, :with_current_and_live_editions) }

      it "supersedes the live edition" do
        live_edition = document.live_edition
        described_class.call(document.current_edition, user, with_review: true)
        expect(live_edition).to be_superseded
      end

      it "doesn't overwrite when the document was first published" do
        expect { described_class.call(document.current_edition, user, with_review: true) }
          .not_to change(document, :first_published_at)
      end
    end

    it "sets the current edition's published_at time" do
      document = create(:document, :with_current_edition)
      freeze_time do
        expect { described_class.call(document.current_edition, user, with_review: true) }
          .to change(document.current_edition, :published_at).to(Time.zone.now)
      end
    end

    it "updates the document's live edition to be the current edition" do
      document = create(:document, :with_current_edition)
      expect { described_class.call(document.current_edition, user, with_review: true) }
        .to change(document, :live_edition).to(document.current_edition)
    end

    it "calls the PublishAssetsService" do
      document = create(:document, :with_current_and_live_editions)
      current_edition = document.current_edition
      expect(PublishAssetsService).to receive(:call)
      described_class.call(current_edition, user, with_review: true)
    end

    it "raises an error when the edition is not current" do
      edition = build(:edition, current: false)
      expect { described_class.call(edition, user, with_review: true) }
        .to raise_error("Only a current edition can be published")
    end

    it "raises an error when the edition is already live" do
      edition = build(:edition, live: true)
      expect { described_class.call(edition, user, with_review: true) }
        .to raise_error("Live editions cannot be published")
    end

    context "when the edition is not associated with a government" do
      let(:past_government) do
        build(:government, ended_on: Time.zone.today)
      end

      let(:current_government) do
        build(:government, started_on: Time.zone.today, current: true)
      end

      before do
        populate_government_bulk_data(past_government, current_government)
      end

      it "tries to associate a government with edition public first published at" do
        edition = create(:edition)
        allow(edition).to receive(:public_first_published_at)
                      .and_return(Time.zone.yesterday)

        expect { described_class.call(edition, user, with_review: true) }
          .to change { edition.government_id }
          .to(past_government.content_id)
      end

      it "associates with current government when the edition hasn't been published" do
        edition = create(:edition)

        expect { described_class.call(edition, user, with_review: true) }
          .to change { edition.government_id }
          .to(current_government.content_id)
      end

      it "updates the preview when a government is associated" do
        edition = create(:edition)
        expect(PreviewDraftEditionService).to receive(:call).with(edition)
        described_class.call(edition, user, with_review: true)
        expect(edition.government_id).to eq(current_government.content_id)
      end

      it "doesn't update the preview when a government isn't associated" do
        populate_government_bulk_data
        edition = create(:edition)

        expect(PreviewDraftEditionService).not_to receive(:call).with(edition)
        described_class.call(edition, user, with_review: true)
        expect(edition.government_id).to be_nil
      end
    end

    context "when the edition is associated with a government" do
      let(:edition) { create(:edition, government: past_government) }

      it "doesn't change the government on the edition" do
        expect { described_class.call(edition, user, with_review: true) }
          .not_to(change(edition, :government_id))
      end

      it "doesn't update the preview of the edition" do
        expect(PreviewDraftEditionService).not_to receive(:call)
        described_class.call(edition, user, with_review: true)
      end
    end

    context "when the edition is access limited" do
      it "removes the access limit" do
        edition = create(:edition, :access_limited)
        described_class.call(edition, user, with_review: true)
        expect(edition.access_limit).to be_nil
      end
    end
  end
end
