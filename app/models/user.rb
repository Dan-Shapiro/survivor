class User < ApplicationRecord
  has_secure_password :pin

  has_many :season_memberships, dependent: :destroy
  has_many :seasons, through: :season_memberships
  has_many :hosted_seasons, class_name: "Season", foreign_key: :host_id, inverse_of: :host, dependent: :restrict_with_error

  normalizes :email, with: ->(email) { email.strip.downcase }

  validates :email, presence: true, uniqueness: true,
    format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :display_name, presence: true
  validates :pin, format: { with: /\A\d{4}\z/, message: "must be exactly 4 digits" }, allow_nil: true

  # No self-serve reset flow (see docs/GAME_DESIGN.md#edge-cases) — a host
  # triggers this and relays the new PIN to the player directly, since
  # there's no email-based reset mechanism for something this minimal.
  # Returns the plaintext PIN because it's the only place it will ever be
  # visible again after this call.
  def reset_pin!
    new_pin = format("%04d", rand(10_000))
    update!(pin: new_pin)
    new_pin
  end
end
