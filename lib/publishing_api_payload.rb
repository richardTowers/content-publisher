class PublishingApiPayload
  PUBLISHING_APP = "content-publisher".freeze

  attr_reader :edition, :document_type, :publishing_metadata, :republish

  def initialize(edition, republish: false)
    @edition = edition
    @document_type = edition.document_type
    @publishing_metadata = document_type.publishing_metadata
    @republish = republish
  end

  def payload
    payload = {
      locale: edition.locale,
      schema_name: publishing_metadata.schema_name,
      document_type: document_type.id,
      publishing_app: PUBLISHING_APP,
      rendering_app: publishing_metadata.rendering_app,
      update_type: edition.update_type,
      details: details,
      links: links,
      access_limited: access_limited,
      auth_bypass_ids: auth_bypass_ids,
      public_updated_at: history.public_updated_at,
    }
    payload[:first_published_at] = history.first_published_at if history.first_published_at.present?

    document_type.contents.each do |field|
      payload.deep_merge!(field.payload(edition))
    end

    if edition.backdated_to.present?
      payload[:first_published_at] = edition.backdated_to
      payload[:public_updated_at] = edition.backdated_to if edition.first?
    end

    if republish
      payload[:update_type] = "republish"
      payload[:bulk_publishing] = true
    end

    payload
  end

private

  def history
    @history ||= History.new(edition)
  end

  def access_limited
    return {} unless edition.access_limit

    { organisations: edition.access_limit_organisation_ids }
  end

  def auth_bypass_ids
    auth_bypass_id = PreviewAuthBypass.new(edition).auth_bypass_id
    [auth_bypass_id]
  end

  def links
    links = edition.tags["primary_publishing_organisation"].to_a +
      edition.tags["organisations"].to_a

    role_appointments = edition.tags["role_appointments"]
    edition.tags
      .except("role_appointments")
      .merge(roles_and_people(role_appointments))
      .merge(organisations: links.uniq)
      .merge(government: [edition.government&.content_id].compact)
      .symbolize_keys
  end

  def image
    {
      high_resolution_url: edition.lead_image_revision.asset_url("high_resolution"),
      url: edition.lead_image_revision.asset_url("300"),
      alt_text: edition.lead_image_revision.alt_text,
      caption: edition.lead_image_revision.caption,
      credit: edition.lead_image_revision.credit,
    }
  end

  def details
    details = {
      political: edition.political?,
      change_history: history.change_history,
    }

    if document_type.lead_image? && edition.lead_image_revision.present?
      details[:image] = image
    end

    details[:documents] = [] if document_type.attachments.featured?

    details
  end

  def roles_and_people(role_appointments)
    return {} if !role_appointments || role_appointments.count.zero?

    role_appointments
      .each_with_object(roles: [], people: []) do |appointment_id, memo|
        response = GdsApi.publishing_api.get_links(appointment_id).to_hash

        roles = response.dig("links", "role") || []
        people = response.dig("links", "person") || []

        memo[:roles] = (memo[:roles] + roles).uniq
        memo[:people] = (memo[:people] + people).uniq
      end
  end
end