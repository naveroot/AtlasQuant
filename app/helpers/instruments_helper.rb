module InstrumentsHelper
  def candlestick_chart_data(candles)
    candles.map do |candle|
      {
        time: candle.traded_at.strftime("%Y-%m-%d"),
        open: candle.open.to_f,
        high: candle.high.to_f,
        low: candle.low.to_f,
        close: candle.close.to_f
      }
    end
  end

  def instrument_summary(candles)
    return if candles.blank?

    first = candles.first
    last = candles.last
    change = last.close - first.close
    change_pct = first.close.zero? ? 0 : (change / first.close * 100)

    {
      last_close: last.close,
      change: change,
      change_pct: change_pct,
      high: candles.map(&:high).max,
      low: candles.map(&:low).min,
      volume: candles.sum(&:volume)
    }
  end

  def change_badge_classes(change)
    if change.positive?
      "bg-green-50 text-green-700 ring-green-600/20"
    elsif change.negative?
      "bg-red-50 text-red-700 ring-red-600/20"
    else
      "bg-gray-50 text-gray-700 ring-gray-500/20"
    end
  end
end
