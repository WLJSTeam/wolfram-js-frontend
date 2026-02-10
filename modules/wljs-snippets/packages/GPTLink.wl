(* ::Package:: *)

(* ::Section:: *)
(*Package Header*)


BeginPackage["CoffeeLiqueur`GPTLink`", {"CoffeeLiqueur`Objects`"}];

GPTUModelsRequest::usage = "
GPTUModelsRequest[endpoint, apiToken, cbk]
"

GPTUChatComplete::usage = 
"GPTUChatComplete[chat] complete given chat. 
GPTUChatCompleteAsync[prompt] complete given prompt. 
GPTUChatCompleteAsync[chat, prompt] complete chat using given prompt."; 


GPTUChatCompleteAsync::usage = 
"GPTUChatCompleteAsync[chat, callback] complete given chat in async mode. 
GPTUChatCompleteAsync[prompt, callback] complete given prompt in async mode. 
GPTUChatCompleteAsync[chat, prompt, callback] complete chat using given prompt in async mode."; 


GPTUChatObject::usage = 
"GPTUChatObject[] symbolic chat representation in Wolfram Language.
GPTUChatObject[\"system\"] symbolic chat representation with system prompt in Wolfram Language."; 


Begin["`Private`"];


(* ::Section:: *)
(*Definitions*)


promptPattern = _String | _Image | {_String, _Image} | {_String, _Graphics} | {_String, Legended[_Graphics, ___]}; 


CreateType[GPTUChatObject, {
	"Endpoint" -> "https://api.openai.com", 
	"Temperature" -> 0.7, 
	"User", 
	"APIToken" :> With[{x = SystemCredential["OPENAI_API_KEY"]}, If[MissingQ[x], "", x] ], 
	"Model" -> "gpt-4o", 
	"MaxTokens" -> 70000, 
	"TotalTokens" -> 0, 
	"Tools" -> {}, 
	"ToolHandler" -> defaultToolHandler,
	"ToolFunction" -> defaultToolFunction,
	"ToolChoice" -> "auto", 
	"Messages" -> {}, 
	"Logger" -> None
}]; 


GPTUChatObject[system_String, opts: OptionsPattern[]] := 
With[{chat = GPTUChatObject[opts]}, 
	chat["Messages"] = Append[chat["Messages"], <|
		"role" -> "system", 
		"date" -> Now,
		"content" -> system
	|>]; 
	chat
]; 


GPTUChatObject /: Append[chat_GPTChatObject, message_Association?AssociationQ] := 
(chat["Messages"] = Append[chat["Messages"], Append[message, "date" -> Now]]; chat); 


GPTUChatObject /: Append[chat_GPTChatObject, message_String?StringQ] := 
Append[chat, <|"role" -> "user", "content" -> message|>]; 


GPTUChatObject /: Append[chat_GPTChatObject, image_Image?ImageQ] := 
With[{imageBase64 = BaseEncode[ExportByteArray[image, "JPEG"], "Base64"]}, 
	Append[chat, <|"role" -> "user", "content" -> {
		<|
			"type" -> "image_url", 
			"image_url" -> <|
				"url" -> StringTemplate["data:image/jpeg;base64,``"][imageBase64]
			|>
		|>
	}|>]
]; 


GPTUChatObject /: Append[chat_GPTChatObject, {text_String?StringQ, image_Image?ImageQ}] := 
With[{imageBase64 = BaseEncode[ExportByteArray[image, "JPEG"], "Base64"]}, 
	Append[chat, <|"role" -> "user", "content" -> {
		<|"type" -> "text", "text" -> text|>, 
		<|
			"type" -> "image_url", 
			"image_url" -> <|
				"url" -> StringTemplate["data:image/jpeg;base64,``"][imageBase64]
			|>
		|>
	}|>]
]; 


GPTUChatObject /: Append[chat_GPTChatObject, {text_String?StringQ, graphics: _Graphics | Legended[_Graphics, ___]}] := 
With[{image = Rasterize[graphics]}, 
	Append[chat, {text, image}]
]; 


Options[GPTUChatCompleteAsync] = {
	"Endpoint" -> Automatic, 
	"Temperature" -> Automatic, 
	"User" -> Automatic, 
	"APIToken" -> Automatic, 
	"Model" -> Automatic, 
	"MaxTokens" -> Automatic, 
	"Tools" -> Automatic, 
	"ToolChoice" -> Automatic, 
	"ToolFunction" -> Automatic,
	"ToolHandler" -> Automatic,
	"Logger" -> Automatic
}; 


GPTUChatCompleteAsync::err = 
"`1`"; 

GPTUModelsRequest[endpoint_, apiToken_, cbk_, args_List:{}] := Module[{url, headers, request},

	url = URLBuild[{endpoint, "v1", "models"}]; 
	
	headers = If[StringQ[apiToken] && TrueQ[StringLength[apiToken] > 0], 
		Join[{
			"x-api-key" -> apiToken,
			"Authorization" -> "Bearer " <> apiToken, 
        	"Accept" -> "application/json"
		}, args]
	,
		args
	];

	request = HTTPRequest[url, <|
		Method -> "GET", 
		"Headers" -> headers
	|>]; 



	URLSubmit[request, 
			HandlerFunctions -> <|
				"BodyReceived" -> Function[Module[{responseBody, responseAssoc}, 
					If[#["StatusCode"] === 200, 
						cbk[<|"Body" -> ImportByteArray[#["BodyByteArray"], "RawJSON", CharacterEncoding -> "UTF-8"], "Event" -> "ResponseBody"|>]; 
					,
						cbk[<|"Error" -> #["StatusCode"], "Body"-> ImportByteArray[#["BodyByteArray"], "Text", CharacterEncoding -> "UTF-8"]|>]
					]
				] ]
			|>,
			HandlerFunctionsKeys -> {"StatusCode", "BodyByteArray", "Headers"}
	];
]

GPTUChatCompleteAsync[chat_GPTChatObject, callback: _Function | _Symbol, 
	secondCall: GPTUChatComplete | GPTUChatCompleteAsync: GPTUChatCompleteAsync, opts: OptionsPattern[]] := 
Module[{ 
	endpoint = ifAuto[OptionValue["Endpoint"], chat["Endpoint"]],  
	apiToken = ifAuto[OptionValue["APIToken"], chat["APIToken"]], 
	model = ifAuto[OptionValue["Model"], chat["Model"]], 
	temperature = ifAuto[OptionValue["Temperature"], chat["Temperature"]], 
	tools = ifAuto[OptionValue["Tools"], chat["Tools"]], 
	toolFunction = ifAuto[OptionValue["ToolFunction"], chat["ToolFunction"]], 
	toolChoice = ifAuto[OptionValue["ToolChoice"], chat["ToolChoice"]], 
	maxTokens = ifAuto[OptionValue["MaxTokens"], chat["MaxTokens"]], 
	logger = ifAuto[OptionValue["Logger"], chat["Logger"]],
	toolHandler = ifAuto[OptionValue["ToolHandler"], chat["ToolHandler"]],
	url, 
	headers, 
	messages, 
	requestAssoc, 
	requestBody, 
	request
}, 
	url = URLBuild[{endpoint, "v1", "chat", "completions"}]; 
	
	headers = If[StringQ[apiToken] && TrueQ[StringLength[apiToken] > 0], 
		{
			"Authorization" -> "Bearer " <> apiToken, 
			"X-API-KEY" -> apiToken
		} 
	,
		{}
	];
	
	messages = chat["Messages"]; 
	
	requestAssoc = <|
		"model" -> model, 
		"messages" -> sanitaze[messages], 
		"temperature" -> temperature, 
		If[# === Nothing, Nothing, "tools" -> #] &@ toolFunction[tools], 
		If[Length[tools] > 0, "tool_choice" -> functionChoice[toolChoice], Nothing]
	|>; 



	requestBody = ExportString[requestAssoc, "RawJSON", CharacterEncoding -> "UTF-8"]; 
	
	request = HTTPRequest[url, <|
		Method -> "POST", 
		"ContentType" -> "application/json", 
		"Headers" -> headers, 
		"Body" -> requestBody
	|>]; 
	
	With[{$request = request, $logger = logger, $requestAssoc = requestAssoc}, 
		URLSubmit[$request, 
			HandlerFunctions -> <|
				"HeadersReceived" -> Function[$logger[<|"Body" -> $requestAssoc, "Event" -> "RequestBody"|>] ], 
				"BodyReceived" -> Function[Module[{responseBody, responseAssoc}, 
					If[#["StatusCode"] === 200, 
						(* responseBody = ExportString[#["Body"], "String"];  *)
						responseAssoc = ImportByteArray[#["BodyByteArray"], "RawJSON", CharacterEncoding -> "UTF-8"]; 

						$logger[<|"Body" -> responseAssoc, "Event" -> "ResponseBody"|>]; 

						If[AssociationQ[responseAssoc], 
							chat["ChatId"] = responseAssoc["id"]; 
							chat["TotalTokens"] = responseAssoc["usage", "total_tokens"]; 
							Append[chat, Join[responseAssoc[["choices", 1, "message"]], <|"date" -> Now|>] ]; 

							If[KeyExistsQ[chat["Messages"][[-1]], "tool_calls"], 
								Module[{
									$cbk,
									msg = chat["Messages"][[-1]]
								}, 
								
									
									$cbk = Function[$result,
									  Do[
										If[StringQ[$result[[ i]]], 
											
											Append[chat, <|
												"role" -> "tool", 
												"content" -> $result[[ i]], 
												"name" -> msg[["tool_calls", i, "function", "name"]], 
												"tool_call_id" -> msg[["tool_calls", i, "id"]],
												"date" -> Now
											|>]; 

										, 
										(*Else*)
											Message[GPTUChatCompleteAsync::err, $result]; $Failed		
										];
									  , {i, Length[$result ]}];

									  Echo["GPTLink >> After tool calls >> Messages:"];
									  $logger[<||>]; 
									  Echo[chat["Messages"] // Length];

									  If[chat["OldMessagesLength"] =!= Length[chat["Messages"] ],
									  	chat["OldMessagesLength"] = Length[chat["Messages"] ];
									  	Echo["GPTLink >> Subcall"];
										GPTUChatCompleteAsync[chat, callback, opts];
			
									  ,
									  	Echo["GPTLink >> Nothing to do. No new messages"];
										callback[chat];
									  ];
									];
									
									
								
									toolHandler[chat["Messages"][[-1]], $cbk];
								];
								
								,
								(*Else*)
								callback[chat];
							
							, 
							(*Else*)
								$logger[<|"Error" -> "No messages provided in the reply"|>]; 
								Message[GPTUChatCompleteAsync::err, responseAssoc]; $Failed
							], 
						(*Else*)
							$logger[<|"Error" -> "Response is not valid JSON"|>]; 
							Message[GPTUChatCompleteAsync::err, responseAssoc]; $Failed
						], 
						Switch[#["StatusCode"],
							401,
								$logger[<|"Error" -> "API key error"|>]; 
								$Failed
							,

							429,
								Echo["GPTLink >> Too many requests. Slow down"];
								SetTimeout[
									Echo["GPTLink >> Trying again..."];
									GPTUChatCompleteAsync[chat, callback, opts];, Quantity[7, "Seconds"] 
								];
							,

							413,
								$logger[<|"Error" -> "Request is too large"|>]; 
								$Failed								
							,

							403,
								$logger[<|"Error" -> "Country, region, or territory not supported"|>]; 
								$Failed	

							,
							
							529,
								$logger[<|"Error" -> "Service is overloaded"|>]; 
								$Failed
							,

							503,
								Echo["GPTLink >> Too many requests. Slow down"];
								Echo[ImportByteArray[#["BodyByteArray"], "Text", CharacterEncoding -> "UTF-8"] ];
								Echo["GPTLink >> We will try in 10 seconds"];
								SetTimeout[
									Echo["GPTLink >> Trying again..."];
									GPTUChatCompleteAsync[chat, callback, opts];, Quantity[10, "Seconds"] 
								];
							,

							_,
							$logger[<|"Error" -> "Response code: "<>ToString[(#["StatusCode"])]|>]; 
							$Failed						
						]
					]
				] ]
			|>, 
			HandlerFunctionsKeys -> {"StatusCode", "BodyByteArray", "Headers"}
		]
	]
]; 


GPTUChatCompleteAsync[chat_GPTChatObject, prompt: promptPattern, callback: _Symbol | _Function, 
	secondCall: GPTUChatComplete | GPTUChatCompleteAsync: GPTUChatCompleteAsync, opts: OptionsPattern[]] := (
	Append[chat, prompt]; 
	GPTUChatCompleteAsync[chat, callback, secondCall, opts]
); 


GPTUChatCompleteAsync[prompt: promptPattern, callback: _Symbol | _Function, 
	secondCall: GPTUChatComplete | GPTUChatCompleteAsync: GPTUChatCompleteAsync, opts: OptionsPattern[]] := 
With[{chat = GPTUChatObject[]}, 
	Append[chat, prompt]; 
	GPTUChatCompleteAsync[chat, callback, secondCall, opts]
]; 


Options[GPTUChatComplete] = Options[GPTUChatCompleteAsync]; 


GPTUChatComplete[chat_GPTChatObject, opts: OptionsPattern[]] := 
(TaskWait[GPTUChatCompleteAsync[chat, Identity, GPTUChatComplete, opts]]; chat); 


GPTUChatComplete[chat_GPTChatObject, prompt: promptPattern, opts: OptionsPattern[]] := 
(TaskWait[GPTUChatCompleteAsync[chat, prompt, Identity, GPTUChatComplete, opts]]; chat); 


GPTUChatComplete[prompt: promptPattern, opts: OptionsPattern[]] := 
With[{chat = GPTUChatObject[]}, TaskWait[GPTUChatCompleteAsync[chat, prompt, Identity, GPTUChatComplete, opts]]; chat]; 


(* ::Sction:: *)
(*Internal*)

ifAuto["Automatic", value_] := value; 
ifAuto[Automatic, value_] := value; 


ifAuto[value_, _] := value; 

defaultToolHandler[message_, cbk_] := With[{},
cbk @ (Table[Module[{func = message[["tool_calls", i, "function", "name"]] // ToExpression},
	Apply[func] @ Values @ ImportByteArray[StringToByteArray @
										message[["tool_calls", i, "function", "arguments"]], "RawJSON", CharacterEncoding -> "UTF-8"
									]
], {i, Length[message[["tool_calls"]]]}])
]


defaultToolFunction[function_Symbol] := 
<|
	"type" -> "function", 
	"function" -> <|
		"name" -> SymbolName[function], 
		"description" -> function::usage, 
		"parameters" -> <|
			"type" -> "object", 
			"properties" -> Apply[Association @* List] @ (
				(
					First[First[DownValues[function]]] /. 
					Verbatim[HoldPattern][function[args___]] :> Hold[args]
				) /. 
				Verbatim[Pattern][$s_Symbol, Verbatim[Blank][$t_]] :> 
				ToString[Unevaluated[$s]] -> <|
					"type" -> ToLowerCase[ToString[$t]], 
					"description" -> ToString[Unevaluated[$s]]
				|>
			)
		|>
	|>
|>; 

defaultToolFunction[list_List] := If[Length[list] > 0, Map[defaultToolFunction] @ list, Nothing]

defaultToolFunction[assoc_Association?AssociationQ] := 
assoc; 


functionChoice[function_Symbol] := 
<|"type" -> "function", "function" -> <|"name" -> SymbolName[function]|>|>; 


functionChoice[Automatic | "auto"] := 
"auto"; 


functionChoice[assoc_Association?AssociationQ] := 
assoc; 


functionChoice[_] := 
"none"; 

sanitaze[list_List] :=  Function[message, KeyDrop[message, "date"] ] /@ list 


(* ::Section:: *)
(*Package Footer*)


End[];


EndPackage[];
