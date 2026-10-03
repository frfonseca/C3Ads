module Triggers
  # Cada tipo é uma classe com a mesma interface (#fired? e #context).
  # Adicionar um tipo novo não toca no job que avalia.
  module Registry
    TYPES = {
      "weather"  => "Triggers::Weather",
      "schedule" => "Triggers::Schedule",
      "manual"   => "Triggers::Manual"
    }.freeze

    def self.build(trigger)
      klass = TYPES.fetch(trigger.kind) { raise ArgumentError, "gatilho desconhecido: #{trigger.kind}" }
      klass.constantize.new(trigger)
    end
  end
end
