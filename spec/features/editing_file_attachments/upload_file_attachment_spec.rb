# frozen_string_literal: true

RSpec.feature "Upload file attachment" do
  scenario do
    given_there_is_an_edition
    when_i_go_to_edit_the_edition
    and_i_go_to_insert_an_attachment
    and_i_upload_a_file_attachment
    then_i_can_see_the_attachment_markdown
    and_the_preview_creation_succeeded
  end

  def given_there_is_an_edition
    body_field = build(:field, id: "body", type: "govspeak")
    document_type = build(:document_type, contents: [body_field])
    @edition = create(:edition, document_type_id: document_type.id)
  end

  def when_i_go_to_edit_the_edition
    visit document_path(@edition.document)
    click_on "Change Content"
  end

  def and_i_go_to_insert_an_attachment
    find("markdown-toolbar details").click
    click_on "Attachment"
  end

  def and_i_upload_a_file_attachment
    @asset_manager_request = stub_asset_manager_receives_an_asset(filename: @attachment_filename)
    @publishing_api_request = stub_publishing_api_put_content(@edition.content_id, {})

    @attachment_filename = "attachment.csv"
    find('form input[type="file"]').set(Rails.root.join(file_fixture(@attachment_filename)))
    fill_in "title", with: "A title"
    click_on "Upload"
  end

  def then_i_can_see_the_attachment_markdown
    expect(page).to have_content("[Attachment: attachment.csv]")
    expect(page).to have_content("[AttachmentLink: attachment.csv]")
  end

  def and_the_preview_creation_succeeded
    expect(@publishing_api_request).to have_been_requested
    expect(@asset_manager_request).to have_been_requested.at_least_once
  end
end