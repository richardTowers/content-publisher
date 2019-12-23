# frozen_string_literal: true

RSpec.describe WhitehallImportedAsset do
  describe ".revision" do
    it "returns a file attachment revision when associated with one" do
      asset = build(:whitehall_imported_asset, :file_attachment)
      expect(asset.revision).to be_kind_of(FileAttachment::Revision)
    end

    it "returns an image revision when associated with one" do
      asset = build(:whitehall_imported_asset, :image)
      expect(asset.revision).to be_kind_of(Image::Revision)
    end
  end

  describe ".associated_with_only_image_or_file_attachment" do
    it "raises a validation error if associated with an image and a file attachment" do
      expect { create(:whitehall_imported_asset, :image, :file_attachment) }
        .to raise_error(
          ActiveRecord::RecordInvalid,
          "Validation failed: Cannot be associated with both image revision AND file attachment revision",
        )
    end
  end
end
