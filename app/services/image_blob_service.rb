# frozen_string_literal: true

require "mini_magick"

class ImageBlobService
  def initialize(revision, user)
    @revision = revision
    @user = user
  end

  def create_blob_revision(file)
    mime_type = Marcel::MimeType.for(file)
    filename = unique_filename(file)
    image_normaliser = ImageNormaliser.new(file.path)

    blob = ActiveStorage::Blob.create_after_upload!(
      io: image_normaliser.normalised_file,
      filename: filename,
      content_type: mime_type,
    )

    blob_revision(blob, filename, image_normaliser)
  end

private

  attr_reader :revision, :user

  def unique_filename(file)
    filenames = revision.image_revisions.map(&:filename)
    UniqueFilenameService.new(filenames).call(file.original_filename)
  end

  def blob_revision(blob, filename, image_normaliser)
    dimensions = image_normaliser.dimensions
    cropper = ImageCentreCropper.new(dimensions[:width],
                                     dimensions[:height],
                                     Image::WIDTH.to_f / Image::HEIGHT)

    Image::BlobRevision.create!(
      blob: blob,
      width: dimensions[:width],
      height: dimensions[:height],
      crop_x: cropper.dimensions[:x],
      crop_y: cropper.dimensions[:y],
      crop_width: cropper.dimensions[:width],
      crop_height: cropper.dimensions[:height],
      filename: filename,
      created_by: user,
    )
  end
end