%%% @doc https://en.wikipedia.org/wiki/Lempel–Ziv–Welch
%%%
%%% Not optimized in any way, written just for fun.
%%%
%%% Copyright 2017 Marcelo Gornstein &lt;marcelog@@gmail.com&gt;
%%%
%%% Licensed under the Apache License, Version 2.0 (the "License");
%%% you may not use this file except in compliance with the License.
%%% You may obtain a copy of the License at
%%%
%%%     http://www.apache.org/licenses/LICENSE-2.0
%%%
%%% Unless required by applicable law or agreed to in writing, software
%%% distributed under the License is distributed on an "AS IS" BASIS,
%%% WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
%%% See the License for the specific language governing permissions and
%%% limitations under the License.
%%% @end
%%% @copyright Marcelo Gornstein <marcelog@gmail.com>
%%% @author Marcelo Gornstein <marcelog@gmail.com>
%%%
-module(lzw).
-author("marcelog@gmail.com").

-export([compress/1, uncompress/3]).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Main entry points.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
compress(Data) ->
  % Start with this many number of bits for the codes in the dictionary
  CodeBits = 9,
  Dict = init(),
  log("Compressing size: ~p", [size(Data)]),
  compress(Data, <<>>, [], CodeBits, Dict).

uncompress(Data, CodeBits, Dict) ->
  log("Uncompressing using ~pbits codes, size: ~p", [CodeBits, size(Data)]),
  RDict = dict_reverse(Dict),
  uncompress(Data, CodeBits, RDict, <<>>).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Dictionary routines.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
init() ->
  Dict = dict_new(),
  lists:foldl(
    fun(S, Acc) ->
      {_, NewDict} = dict_save(<<S:8/integer>>, Acc),
      NewDict
    end,
    Dict,
    lists:seq(0, 255)
  ).

dict_new() ->
  maps:new().

dict_reverse(Dict) ->
  maps:fold(
    fun(K, V, Acc) -> maps:put(V, K, Acc) end,
    dict_new(),
    Dict
  ).

dict_save(String, Dict) ->
  NewCode = maps:size(Dict) + 1,
  NewDict = maps:put(String, NewCode, Dict),
  {NewCode, NewDict}.

dict_contains(String, Dict) ->
  maps:is_key(String, Dict).

dict_get_code(String, Dict) ->
  maps:get(String, Dict).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Compression routines.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
compress(<<>>, CurrentBuffer, Output, CodeBits, Dict) ->
  NewOutput = case CurrentBuffer of
    <<>> -> Output;
    _ ->
      NewCode = dict_get_code(CurrentBuffer, Dict),
      [NewCode|Output]
  end,

  BinOutput = lists:foldl(
    fun(Code, Acc) -> <<Code:CodeBits/integer, Acc/bitstring>> end,
    <<>>,
    NewOutput
  ),
  log("Compressed with ~pbits codes to size: ~p", [CodeBits, size(BinOutput)]),
  {BinOutput, CodeBits, Dict};

compress(
  <<A:8/integer, Rest/binary>> = Bin,
  CurrentBuffer,
  Output,
  CodeBits,
  Dict
) ->
  NewCurrentBuffer = <<CurrentBuffer/binary, A/integer>>,
  log("Analyzing ~p", [NewCurrentBuffer]),
  case dict_contains(NewCurrentBuffer, Dict) of
    true ->
      log("~p is in the dictionary, continuing", [NewCurrentBuffer]),
      compress(Rest, NewCurrentBuffer, Output, CodeBits, Dict);
    false ->
      Code = dict_get_code(CurrentBuffer, Dict),
      {NewCode, NewDict} = dict_save(NewCurrentBuffer, Dict),
      NewOutput = [Code|Output],

      % Check if we need to adjust the number of bits for the dictionary codes.
      MaxCode = math:pow(2, CodeBits),
      NewCodeBits = case NewCode of
        _ when NewCode > MaxCode -> CodeBits + 1;
        _ -> CodeBits
      end,
      log(
        "Added ~p to the dictionary, Outputing: ~p",
        [NewCurrentBuffer, Code]
      ),
      compress(Bin, <<>>, NewOutput, NewCodeBits, NewDict)
  end.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Uncompression routines.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
uncompress(<<>>, _CodeBits, _Dict, Output) ->
  log("Uncompressed to size: ~p", [size(Output)]),
  Output;

uncompress(Bin, CodeBits, Dict, Output) ->
  case Bin of
    <<Code:CodeBits/integer, Rest/bitstring>> ->
      String = dict_get_code(Code, Dict),
      NewOutput = <<Output/binary, String/binary>>,
      uncompress(Rest, CodeBits, Dict, NewOutput);
    <<Code:CodeBits/integer>> ->
      String = dict_get_code(Code, Dict),
      <<Output/binary, String/binary>>
  end.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Misc routines.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
log(Msg, Args) ->
  io:format(Msg, Args),
  io:format("~n").
