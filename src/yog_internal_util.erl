-module(yog_internal_util).
-export([array_from_list/1, array_to_list/2, array_get/2, array_set/3]).

%% Using erlang:array for O(log n) performance instead of O(n) tuples
%% Note: array indices are 0-based, which matches our requirements.

array_from_list(List) ->
    array:from_list(List).

array_to_list(Arr, _Size) ->
    array:to_list(Arr).

array_get(Arr, Index) ->
    array:get(Index, Arr).

array_set(Arr, Index, Value) ->
    array:set(Index, Value, Arr).
