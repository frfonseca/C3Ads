module Triggers
  # Previsão do tempo via Open-Meteo — gratuita e sem API key.
  #
  # Condição: { latitude:, longitude:, metric:, op:, value:, horizon_hours: }
  class Weather < Base
    API = "https://api.open-meteo.com".freeze
    METRICS = {
      "precipitation_probability" => "precipitation_probability",
      "temperature" => "temperature_2m"
    }.freeze

    def fired?
      value = peak_value
      return false if value.nil?

      @observed = value
      compare(value, @condition["value"].to_f)
    end

    def context
      return {} if @observed.nil?

      metric = @condition["metric"] || "precipitation_probability"
      { "weather" => { "metric" => metric, "value" => @observed,
                       "horizon_hours" => horizon,
                       "description" => describe(metric, @observed) } }
    end

    def reason = "#{@condition['metric']} = #{@observed} nas próximas #{horizon}h"

    private

    def horizon = (@condition["horizon_hours"] || 24).to_i

    def peak_value
      field = METRICS.fetch(@condition["metric"] || "precipitation_probability", "precipitation_probability")
      response = connection.get("/v1/forecast",
                                latitude: @condition["latitude"],
                                longitude: @condition["longitude"],
                                hourly: field, forecast_days: 2, timezone: "America/Sao_Paulo")
      return nil unless response.success?

      Array(response.body.dig("hourly", field)).compact.first(horizon).max
    rescue StandardError => e
      Rails.logger.warn("[Triggers::Weather] #{e.class}: #{e.message}")
      nil
    end

    def compare(actual, expected)
      case @condition["op"]
      when ">", "gt" then actual > expected
      when "<", "lt" then actual < expected
      when ">=" then actual >= expected
      when "<=" then actual <= expected
      else actual > expected
      end
    end

    def describe(metric, value)
      case metric
      when "precipitation_probability"
        "previsão de #{value.to_i}% de chance de chuva nas próximas #{horizon} horas"
      when "temperature"
        "previsão de #{value.to_i}°C nas próximas #{horizon} horas"
      else
        "#{metric}: #{value}"
      end
    end

    def connection
      @connection ||= Faraday.new(url: API) do |f|
        f.response :json
        f.options.timeout = 15
        f.adapter Faraday.default_adapter
      end
    end
  end
end
