module Triggers
  # Acionado pela interface, não pelo cron. Isento de debounce: se a pessoa
  # clicou, ela quis.
  class Manual < Base
    def initialize(trigger, note: nil)
      super(trigger)
      @note = note
    end

    def fired? = true

    def context = @note.present? ? { "note" => @note } : {}

    def reason = "disparo manual"
  end
end
