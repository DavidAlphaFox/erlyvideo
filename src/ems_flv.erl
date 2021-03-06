%%% @author     Roberto Saccon <rsaccon@gmail.com> [http://rsaccon.com]
%%% @author     Stuart Jackson <simpleenigmainc@gmail.com> [http://erlsoft.org]
%%% @author     Luke Hubbard <luke@codegent.com> [http://www.codegent.com]
%%% @copyright  2007 Luke Hubbard, Stuart Jackson, Roberto Saccon
%%% @doc        RTMP encoding/decoding and command handling module
%%% @reference  See <a href="http://erlyvideo.googlecode.com" target="_top">http://erlyvideo.googlecode.com</a> for more information
%%% @end
%%%
%%%
%%% The MIT License
%%%
%%% Copyright (c) 2007 Luke Hubbard, Stuart Jackson, Roberto Saccon
%%%
%%% Permission is hereby granted, free of charge, to any person obtaining a copy
%%% of this software and associated documentation files (the "Software"), to deal
%%% in the Software without restriction, including without limitation the rights
%%% to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
%%% copies of the Software, and to permit persons to whom the Software is
%%% furnished to do so, subject to the following conditions:
%%%
%%% The above copyright notice and this permission notice shall be included in
%%% all copies or substantial portions of the Software.
%%%
%%% THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
%%% IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
%%% FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
%%% AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
%%% LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
%%% OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
%%% THE SOFTWARE.
%%%
%%%---------------------------------------------------------------------------------------
-module(ems_flv).
-author('rsaccon@gmail.com').
-author('simpleenigmainc@gmail.com').
-author('luke@codegent.com').
-include("../include/ems.hrl").
-include("../include/flv.hrl").

-export([to_tag/1, encode/1]).


encode(#video_frame{type = ?FLV_TAG_TYPE_AUDIO,
                    decoder_config = true,
                    sound_format = ?FLV_AUDIO_FORMAT_AAC,
                	  sound_type	= SoundType,
                	  sound_size	= SoundSize,
                	  sound_rate	= SoundRate,
                    body = Body}) when is_binary(Body) ->
  <<?FLV_AUDIO_FORMAT_AAC:4, SoundRate:2, SoundSize:1, SoundType:1, 
    ?FLV_AUDIO_AAC_SEQUENCE_HEADER:8, Body/binary>>;


encode(#video_frame{type = ?FLV_TAG_TYPE_AUDIO,
                    sound_format = ?FLV_AUDIO_FORMAT_AAC,
                	  sound_type	= SoundType,
                	  sound_size	= SoundSize,
                	  sound_rate	= SoundRate,
                    body = Body}) when is_binary(Body) ->
	<<?FLV_AUDIO_FORMAT_AAC:4, SoundRate:2, SoundSize:1, SoundType:1, 
	  ?FLV_AUDIO_AAC_RAW:8, Body/binary>>;


encode(#video_frame{type = ?FLV_TAG_TYPE_VIDEO,
                    frame_type = FrameType,
                   	decoder_config = true,
                   	codec_id = CodecId,
                    body = Body}) when is_binary(Body) ->
  CompositionTime = 0,
	<<FrameType:4/integer, CodecId:4/integer, ?FLV_VIDEO_AVC_SEQUENCE_HEADER:8/integer, CompositionTime:24/big-integer, Body/binary>>;

encode(#video_frame{type = ?FLV_TAG_TYPE_VIDEO,
                    frame_type = FrameType,
                   	codec_id = CodecId,
                    body = Body}) when is_binary(Body) ->
  CompositionTime = 0,
	<<FrameType:4/integer, CodecId:4/integer, ?FLV_VIDEO_AVC_NALU:8/integer, CompositionTime:24/big-integer, Body/binary>>;


encode(_Frame) ->
  ?D({"Request to encode undefined", _Frame}).


to_tag(#channel{msg = Msg, type = Type, stream = StreamId, timestamp = CurrentTimeStamp}) ->
	BodyLength = size(Msg),	
	{TimeStampExt, TimeStamp} = case CurrentTimeStamp of
		<<TimeStampExt1:8,TimeStamp1:32>> -> 
			{TimeStampExt1, TimeStamp1};
		_ ->
			{0, CurrentTimeStamp}
	end,			
	PrevTagSize = size(Msg) + 11,
	<<Type:8,BodyLength:24,TimeStamp:24,TimeStampExt:8,StreamId:24,Msg/binary,PrevTagSize:32>>.

