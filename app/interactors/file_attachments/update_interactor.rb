# frozen_string_literal: true

class FileAttachments::UpdateInteractor
  include Interactor

  delegate :params,
           :user,
           :edition,
           :file_attachment_revision,
           to: :context

  def call
    Edition.transaction do
      find_and_lock_edition
      find_and_update_file_attachment

      check_for_issues
      update_edition

      create_timeline_entry
      update_preview
    end
  end

private

  def find_and_lock_edition
    context.edition = Edition.lock.find_current(document: params[:document])
  end

  def find_and_update_file_attachment
    current_attachment_revision = edition.file_attachment_revisions
                                         .find_by!(file_attachment_id: params[:file_attachment_id])

    updater = Versioning::FileAttachmentRevisionUpdater.new(current_attachment_revision, user)
    attributes = attachment_params.slice(:title)
                                  .merge(file_attachment_attributes(current_attachment_revision))

    updater.assign(attributes)

    context.file_attachment_revision = updater.next_revision
  end

  def attachment_params
    params.require(:file_attachment).permit(:file, :title)
  end

  def file_attachment_attributes(file_attachment_revision)
    return {} unless attachment_params[:file]

    blob_service = FileAttachmentBlobService.new(file: attachment_params[:file],
                                                 revision: edition.revision,
                                                 replacement: file_attachment_revision)

    {
      blob_id: blob_service.blob_id,
      filename: blob_service.filename,
      number_of_pages: blob_service.number_of_pages,
    }
  end

  def check_for_issues
    checker = Requirements::FileAttachmentChecker.new(title: file_attachment_revision.title)
    issues = checker.pre_update_issues

    context.fail!(issues: issues) if issues.any?
  end

  def update_edition
    updater = Versioning::RevisionUpdater.new(edition.revision, user)
    updater.update_file_attachment(file_attachment_revision)

    context.fail! unless updater.changed?

    edition.assign_revision(updater.next_revision, user).save!
  end

  def create_timeline_entry
    TimelineEntry.create_for_revision(entry_type: :file_attachment_updated,
                                      edition: edition)
  end

  def update_preview
    PreviewService.new(edition).try_create_preview
  end
end
