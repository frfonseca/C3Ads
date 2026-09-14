class Account < ApplicationRecord
  has_many :projects, dependent: :nullify
  has_many :posts, dependent: :nullify

  validates :name, presence: true

  # Token de longa duração da Meta dura ~60 dias e precisa ser renovado ANTES
  # de vencer — depois disso só refazendo o OAuth na mão.
  RENEWAL_WINDOW = 15.days
  ALERT_WINDOW   = 7.days

  scope :needing_token_refresh, lambda {
    where.not(token_expires_at: nil).where(token_expires_at: ..RENEWAL_WINDOW.from_now)
  }

  def token_expiring_soon? = token_expires_at.present? && token_expires_at <= ALERT_WINDOW.from_now
  def token_expired?       = token_expires_at.present? && token_expires_at <= Time.current
  def connected?           = ig_user_id.present? && access_token.present?
end
