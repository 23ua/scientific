%%%-------------------------------------------------------------------
%%% @author 23ua
%%% @copyright (C) 2016
%%% @doc
%%%
%%% @end
%%% Created : 17. Sep 2016 10:36
%%%-------------------------------------------------------------------
-module(scientific).
-author("23ua").

%% API
-export([
    new/2,
    from_str/1,
    to_str/1,
    plus/2,
    minus/2,
    multiply/2,
    from_integer/1]).


-record(scientific, {
    coefficient :: integer(),
    exponent :: integer()
}).


-type scientific() :: #scientific{}.
-type math_fun_2() :: fun((integer(), integer()) -> integer()).


%%====================================================================
%% API functions
%%====================================================================

-spec from_str(binary()) -> scientific().
from_str(Str) when is_binary(Str) ->
    case binary:split(Str, <<".">>) of
        [_, Fractional] ->
            Exp = size(Fractional),
            IntegralStr = binary:replace(Str, <<".">>, <<>>),
            #scientific{
                coefficient = binary_to_integer(IntegralStr),
                exponent = -Exp
            };
        _ ->
            throw({error, {badarg, Str}})
    end.


-spec to_str(scientific()) -> binary().
to_str(#scientific{coefficient = Coef, exponent = 0}) ->
    iolist_to_binary([integer_to_binary(Coef), <<".">>]);

to_str(#scientific{coefficient = Coef, exponent = Exp}) when Exp > 0
                                                        andalso is_integer(Exp) ->
    iolist_to_binary([
        integer_to_binary(Coef),
        <<".">>, lists:duplicate(Exp, <<"0">>)
    ]);

to_str(#scientific{coefficient = Coef, exponent = Exp}) when Exp < 0
                                                        andalso is_integer(Exp) ->
    CoefStr = integer_to_binary(Coef),
    IntLen = size(CoefStr) + Exp,
    <<Int:IntLen/binary, Frac/binary>> = CoefStr,
    iolist_to_binary([Int, <<".">>, Frac]).


-spec plus(scientific(), scientific()) -> scientific().
plus(S1, S2) ->
    plus_helper(S1, S2, fun erlang:'+'/2).

-spec minus(scientific(), scientific()) -> scientific().
minus(S1, S2) ->
    plus_helper(S1, S2, fun erlang:'-'/2).

-spec multiply(scientific(), scientific()) -> scientific().
multiply(#scientific{exponent = Exp1, coefficient = Coef1},
         #scientific{exponent = Exp2, coefficient = Coef2}) ->
    #scientific{coefficient = Coef1 + Coef2, exponent = Exp1 + Exp2}.

-spec from_integer(integer()) -> scientific().
from_integer(Int) when is_integer(Int) ->
    #scientific{coefficient = Int, exponent = 0}.

%%====================================================================
%% Internal functions
%%====================================================================
-spec plus_helper(scientific(), scientific(), math_fun_2())-> scientific().
plus_helper(#scientific{exponent = Exp1, coefficient = Coef1},
            #scientific{exponent = Exp2, coefficient = Coef2}, Fun) when Exp1 < Exp2 ->
    %% FIXME: integral exponentiation needed
    LF = math:pow(10, Fun(Exp2, Exp1)),
    L = round_integral(LF),
    #scientific{coefficient = Coef1 + (Coef2 * L), exponent = Exp1};

plus_helper(#scientific{exponent = Exp1, coefficient = Coef1},
            #scientific{exponent = Exp2, coefficient = Coef2}, Fun) ->
    %% FIXME: integral exponentiation needed
    RF = math:pow(10, Fun(Exp1, Exp2)),
    R = round_integral(RF),
    #scientific{coefficient = (Coef1 * R) + Coef2, exponent = Exp2}.


-spec round_integral(number()) -> integer().
round_integral(Num) when Num >= 0 andalso is_number(Num) ->
    trunc(Num + 0.1);

round_integral(Num) when Num < 0 andalso is_number(Num) ->
    trunc(Num - 0.1).
