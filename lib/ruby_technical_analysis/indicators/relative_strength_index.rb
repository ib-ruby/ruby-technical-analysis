module RubyTechnicalAnalysis
  # Relative Momentum Index indicator
  # Returns a single value
  class RelativeStrengthIndex < Indicator
    attr_reader :period

    def initialize(price_series, period)
      @period = period
      @rsi = []
      @smooth_up = []
      @smooth_down = []
      @wilders_is_set = false

      super(price_series)
    end

    def call
      calculate_rsi
    end

    private

    def _smooth_coef_one
      @_smooth_coef_one ||= (1.0 / period).round(4)
    end

    def _smooth_coef_two
      @_smooth_coef_two ||= (1 - _smooth_coef_one)
    end

    def calculate_channels(cla)
      period.times.map do |index|
        diff = (cla.at(index) - cla.at(index + 1)).round(4)

        [diff.negative? ? diff.abs : 0, diff.positive? ? diff : 0]
      end.transpose
    end

    def calculate_initial_smoothing(up_ch, down_ch)
      @smooth_up << RubyTechnicalAnalysis::WildersSmoothing.new(up_ch, period).call
      @smooth_down << RubyTechnicalAnalysis::WildersSmoothing.new(down_ch, period).call

      @wilders_is_set = true
    end

    def calculate_subsequent_smoothing(up_ch, down_ch)
      @smooth_up << (_smooth_coef_one * up_ch.last + _smooth_coef_two * @smooth_up.last).round(4)
      @smooth_down << (_smooth_coef_one * down_ch.last + _smooth_coef_two * @smooth_down.last).round(4)
    end

    def calculate_smoothing(up_ch, down_ch)
      @wilders_is_set ? calculate_subsequent_smoothing(up_ch, down_ch) : calculate_initial_smoothing(up_ch, down_ch)
    end

    def calculate_rsi
      (0..(price_series.size - period - 1)).flat_map do |index|
        cla = price_series[index..index + period]
        up_ch, down_ch = calculate_channels(cla)

        calculate_smoothing(up_ch, down_ch)
        @rsi << (100.00 - (100.00 / ((@smooth_up.last.to_f / @smooth_down.last) + 1))).round(4)
      end.last
    end
  end
end