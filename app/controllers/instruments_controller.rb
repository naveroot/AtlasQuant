class InstrumentsController < ApplicationController
  DEFAULT_RANGE_DAYS = 30

  def index
    @instruments = Moex::CurrencyFutures::List.call
  rescue Moex::Client::Error => e
    @instruments = []
    flash.now[:alert] = "Unable to load instruments from MOEX: #{e.message}"
  end

  def show
    @instrument = find_instrument(params[:secid])
    return unless @instrument

    track_analytics_event(Analytics::TrackEvent::VIEW_INSTRUMENT, secid: @instrument.secid)
    track_analytics_event(Analytics::TrackEvent::VIEW_BASIS, secid: @instrument.secid)

    @from, @till = date_range
    @candles = Moex::CurrencyFutures::HistoricalCandles.call(
      secid: @instrument.secid,
      from: @from,
      till: @till
    )
  rescue Moex::Client::Error => e
    redirect_to instruments_path, alert: "Unable to load chart data from MOEX: #{e.message}"
  end

  private

  def find_instrument(secid)
    instrument = Moex::CurrencyFutures::List.call.find { |entry| entry.secid == secid }

    unless instrument
      redirect_to instruments_path, alert: "Instrument #{secid} not found."
      return
    end

    instrument
  rescue Moex::Client::Error => e
    redirect_to instruments_path, alert: "Unable to load instruments from MOEX: #{e.message}"
    nil
  end

  def date_range
    till = parse_date(params[:till]) || Date.current
    from = parse_date(params[:from]) || (till - DEFAULT_RANGE_DAYS.days)

    if from > till
      from = till - DEFAULT_RANGE_DAYS.days
    end

    [ from, till ]
  end

  def parse_date(value)
    return if value.blank?

    Date.iso8601(value)
  rescue Date::Error
    nil
  end
end
