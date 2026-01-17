(* ::Package:: *)

(* ::Section:: *)
(*Package Header*)


BeginPackage["KirillBelov`GPTLink`", {"KirillBelov`Objects`"}];


GPTChatComplete::usage = 
"GPTChatComplete[chat] complete given chat. 
GPTChatCompleteAsync[prompt] complete given prompt. 
GPTChatCompleteAsync[chat, prompt] complete chat using given prompt."; 


GPTChatCompleteAsync::usage = 
"GPTChatCompleteAsync[chat, callback] complete given chat in async mode. 
GPTChatCompleteAsync[prompt, callback] complete given prompt in async mode. 
GPTChatCompleteAsync[chat, prompt, callback] complete chat using given prompt in async mode."; 


GPTChatObject::usage = 
"GPTChatObject[] symbolic chat representation in Wolfram Language.
GPTChatObject[\"system\"] symbolic chat representation with system prompt in Wolfram Language."; 


Begin["`Private`"];


(* ::Section:: *)
(*Definitions*)


promptPattern = _String | _Image | {_String, _Image} | {_String, _Graphics} | {_String, Legended[_Graphics, ___]}; 


CreateType[GPTChatObject, {
	"Endpoint" -> "https://api.openai.com", 
	"Temperature" -> 0.7, 
	"User", 
	"APIToken" :> With[{x = SystemCredential["OPENAI_API_KEY"]}, If[MissingQ[x], "", x] ], 
	"Model" -> "gpt-4o-mini", 
	"MaxTokens" -> 70000, 
	"TotalTokens" -> 0, 
	"Tools" -> {}, 
	"ToolHandler" -> defaultToolHandler,
	"ToolFunction" -> defaultToolFunction,
	"ToolChoice" -> "auto", 
	"Messages" -> {}, 
	"Logger" -> None
}]; 


GPTChatObject[system_String, opts: OptionsPattern[]] := 
With[{chat = GPTChatObject[opts]}, 
	chat["Messages"] = Append[chat["Messages"], <|
		"role" -> "system", 
		"date" -> Now,
		"content" -> system
	|>]; 
	chat
]; 


GPTChatObject /: Append[chat_GPTChatObject, message_Association?AssociationQ] := 
(chat["Messages"] = Append[chat["Messages"], Append[message, "date" -> Now]]; chat); 


GPTChatObject /: Append[chat_GPTChatObject, message_String?StringQ] := 
Append[chat, <|"role" -> "user", "content" -> message|>]; 


GPTChatObject /: Append[chat_GPTChatObject, image_Image?ImageQ] := 
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


GPTChatObject /: Append[chat_GPTChatObject, {text_String?StringQ, image_Image?ImageQ}] := 
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


GPTChatObject /: Append[chat_GPTChatObject, {text_String?StringQ, graphics: _Graphics | Legended[_Graphics, ___]}] := 
With[{image = Rasterize[graphics]}, 
	Append[chat, {text, image}]
]; 


Options[GPTChatCompleteAsync] = {
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


GPTChatCompleteAsync::err = 
"`1`"; 


GPTChatCompleteAsync[chat_GPTChatObject, callback: _Function | _Symbol, 
	secondCall: GPTChatComplete | GPTChatCompleteAsync: GPTChatCompleteAsync, opts: OptionsPattern[]] := 
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
											Message[GPTChatCompleteAsync::err, $result]; $Failed		
										];
									  , {i, Length[$result ]}];

									  Echo["GPTLink >> After tool calls >> Messages:"];
									  $logger[<||>]; 
									  Echo[chat["Messages"] // Length];

									  If[chat["OldMessagesLength"] =!= Length[chat["Messages"] ],
									  	chat["OldMessagesLength"] = Length[chat["Messages"] ];
									  	Echo["GPTLink >> Subcall"];
										GPTChatCompleteAsync[chat, callback, opts];
			
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
								Message[GPTChatCompleteAsync::err, responseAssoc]; $Failed
							], 
						(*Else*)
							$logger[<|"Error" -> "Response is not valid JSON"|>]; 
							Message[GPTChatCompleteAsync::err, responseAssoc]; $Failed
						], 
						$logger[<|"Error" -> "Response code: "<>ToString[(#["StatusCode"])]|>]; 
						$Failed
					]
				] ]
			|>, 
			HandlerFunctionsKeys -> {"StatusCode", "BodyByteArray", "Headers"}
		]
	]
]; 


GPTChatCompleteAsync[chat_GPTChatObject, prompt: promptPattern, callback: _Symbol | _Function, 
	secondCall: GPTChatComplete | GPTChatCompleteAsync: GPTChatCompleteAsync, opts: OptionsPattern[]] := (
	Append[chat, prompt]; 
	GPTChatCompleteAsync[chat, callback, secondCall, opts]
); 


GPTChatCompleteAsync[prompt: promptPattern, callback: _Symbol | _Function, 
	secondCall: GPTChatComplete | GPTChatCompleteAsync: GPTChatCompleteAsync, opts: OptionsPattern[]] := 
With[{chat = GPTChatObject[]}, 
	Append[chat, prompt]; 
	GPTChatCompleteAsync[chat, callback, secondCall, opts]
]; 


Options[GPTChatComplete] = Options[GPTChatCompleteAsync]; 


GPTChatComplete[chat_GPTChatObject, opts: OptionsPattern[]] := 
(TaskWait[GPTChatCompleteAsync[chat, Identity, GPTChatComplete, opts]]; chat); 


GPTChatComplete[chat_GPTChatObject, prompt: promptPattern, opts: OptionsPattern[]] := 
(TaskWait[GPTChatCompleteAsync[chat, prompt, Identity, GPTChatComplete, opts]]; chat); 


GPTChatComplete[prompt: promptPattern, opts: OptionsPattern[]] := 
With[{chat = GPTChatObject[]}, TaskWait[GPTChatCompleteAsync[chat, prompt, Identity, GPTChatComplete, opts]]; chat]; 


(* ::Sction:: *)
(*Internal*)


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
