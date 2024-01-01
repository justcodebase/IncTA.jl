const STOCH_PERIOD = 14
const STOCH_SMOOTHING_PERIOD = 3

struct StochVal{Tprice}
    k::Tprice
    d::Tprice
end

"""
    Stoch{Tohlcv,S}(; period = STOCH_PERIOD, smoothing_period = STOCH_SMOOTHING_PERIOD, ma = SMA, input_filter = always_true, input_modifier = identity, input_modifier_return_type = Tohlcv)

The `Stoch` type implements the Stochastic indicator.
"""
mutable struct Stoch{Tohlcv,S} <: TechnicalIndicator{Tohlcv}
    value::Union{Missing,StochVal}
    n::Int
    output_listeners::Series
    input_indicator::Union{Missing,TechnicalIndicator}

    period::Integer
    smoothing_period::Integer

    values_d::SMA

    input_modifier::Function
    input_filter::Function
    input_values::CircBuff

    function Stoch{Tohlcv,S}(;
        period = STOCH_PERIOD,
        smoothing_period = STOCH_SMOOTHING_PERIOD,
        ma = SMA,
        input_filter = always_true,
        input_modifier = identity,
        input_modifier_return_type = Tohlcv,
    ) where {Tohlcv,S}
        Tstore = input_modifier_return_type
        values_d = MAFactory(S)(ma, period = smoothing_period)
        input_values = CircBuff(Tstore, period, rev = false)
        new{Tohlcv,S}(
            initialize_indicator_common_fields()...,
            period,
            smoothing_period,
            values_d,
            input_modifier,
            input_filter,
            input_values,
        )
    end
end

function _calculate_new_value(ind::Stoch)
    # get latest received candle
    candle = ind.input_values[end]
    # get max high and min low
    max_high = max([cdl.high for cdl in value(ind.input_values)]...)
    min_low = min([cdl.low for cdl in value(ind.input_values)]...)
    # calculate k
    if max_high == min_low
        k = 100.0
    else
        k = 100.0 * (candle.close - min_low) / (max_high - min_low)
    end
    # calculate d
    fit!(ind.values_d, k)
    if length(ind.values_d.value) > 0
        d = value(ind.values_d)
    else
        d = missing
    end
    return StochVal(k, d)
end
