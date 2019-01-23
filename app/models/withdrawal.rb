# frozen_string_literal: true

# Stores the specific data for a withdrawn status.
#
# This model is immutable
class Withdrawal < ApplicationRecord
  has_one :status, as: :details

  def readonly?
    !new_record?
  end
end
