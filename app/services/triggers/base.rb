module Triggers
  class Base
    def initialize(trigger)
      @trigger = trigger
      @condition = trigger.condition || {}
    end

    def fired? = raise(NotImplementedError)

    # Vira o contexto do prompt de geração.
    def context = {}

    def reason = nil
  end
end
