const MassIndex_MA_PERIOD = 9
const MassIndex_MA_MA_PERIOD = 9
const MassIndex_MA_RATIO_PERIOD = 10


"""
    MassIndex{T,S}(; ma_period = MassIndex_MA_PERIOD, ma_ma_period = MassIndex_MA_MA_PERIOD, ma_ratio_period = MassIndex_MA_RATIO_PERIOD, ma = EMA, input_filter = always_true, input_modifier = identity, input_modifier_return_type = T)

The `MassIndex` type implements a Commodity Channel Index.
"""
mutable struct MassIndex{Tohlcv,S} <: TechnicalIndicator{Tohlcv}
    value::Union{Missing,S}
    n::Int
    output_listeners::Series
    input_indicator::Union{Missing,TechnicalIndicator}

    ma_ratio_period::Integer

    ma::MovingAverageIndicator  # EMA
    ma_ma::MovingAverageIndicator  # EMA
    ma_ratio::CircBuff{S}

    input_modifier::Function
    input_filter::Function

    function MassIndex{Tohlcv,S}(;
        ma_period = MassIndex_MA_PERIOD,
        ma_ma_period = MassIndex_MA_MA_PERIOD,
        ma_ratio_period = MassIndex_MA_RATIO_PERIOD,
        ma = EMA,
        input_filter = always_true,
        input_modifier = identity,
        input_modifier_return_type = Tohlcv,
    ) where {Tohlcv,S}
        _ma = MAFactory(S)(ma, period = ma_period)
        _ma_ma = MAFactory(S)(ma, period = ma_ma_period)
        _ma_ratio = CircBuff(S, ma_ratio_period, rev = false)
        new{Tohlcv,S}(
            initialize_indicator_common_fields()...,
            ma_ratio_period,
            _ma,
            _ma_ma,
            _ma_ratio,
            input_modifier,
            input_filter,
        )
    end
end

function _calculate_new_value_only_from_incoming_data(ind::MassIndex, candle)
    fit!(ind.ma, candle.high - candle.low)

    if !has_output_value(ind.ma)
        return missing
    end

    fit!(ind.ma_ma, value(ind.ma))

    if !has_output_value(ind.ma_ma)
        return missing
    end

    fit!(ind.ma_ratio, value(ind.ma) / value(ind.ma_ma))

    if length(ind.ma_ratio) < ind.ma_ratio_period
        return missing
    end

    return sum(value(ind.ma_ratio))
end
