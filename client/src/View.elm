module View exposing (view)
{-| This module includes all view of OpenIRC.

# Top-level View

@docs view
-}

import Html exposing (..)
import Html.Events exposing (onSubmit, onInput, onClick)
import Html.Attributes exposing (id, class, type_, placeholder, value, autocomplete)
import Dict as D
import Tuple exposing (second)
-- Local modules
import Model exposing (..)
import Update exposing (Msg(..))

{-| Top-level view of OpenIRC. It consists of two components - `bufferListsDiv` showing information about all open
buffer(sidebar), and `currentBufferDiv` showing information about the current buffer.
-}
view : Model -> Html Msg
view model =
  div [ id "openirc" ]
    [ bufferListsDiv model
    , currentBufferDiv model
    ]


{-| Div showing information of all open buffer, indexed by server (sidebar).

TODO: Support multi-server architecture - multiple `<ul>` must be able to exist
-}
bufferListsDiv : Model -> Html Msg
bufferListsDiv model =
  div [ id "buffer-lists" ]
    [ ul [ class "buffer-list" ]
      ([ serverNameItem "InitServer" ] ++ bufferNameItems model ++ [ newBufferItem model ])
    ]


{-| List item showing a server name.

```elm
relatedMsgs : List Msg
relatedMsgs == [ ChangeBuffer ]
```
-}
serverNameItem : ServerName -> Html Msg
serverNameItem name =
  let
    serverNameSpan serverName =
      span
        [ onClick <| ChangeBuffer ( serverName, serverBufferKey ) ]
        [ text serverName ]
  in
    li [ class "buffer-item server-name" ] [ serverNameSpan name ]


{-| `List` of list items, where each of them showing the name of a open buffer.
TODO: Add server name to arguement, only show namePairs which belongs to the server.

```elm
relatedMsgs : List Msg
relatedMsgs == [ ChangeBuffer, CloseBuffer ]
```
-}
bufferNameItems : Model -> List (Html Msg)
bufferNameItems model =
  let
    itemClass namePair =
      if namePair == ( model.currentServerName, model.currentChannelName ) then
        "buffer-item buffer-name buffer-selected"
      else
        "buffer-item buffer-name"

    bufferNameSpan namePair =
      span
        [ onClick <| ChangeBuffer namePair ]
        [ text <| second namePair ]

    closeAnchor namePair =
      a [ class "buffer-close", onClick <| CloseBuffer namePair ] [ text "✘" ]

    render =
      (\namePair ->
        li
          [ class <| itemClass namePair ]
          [ bufferNameSpan namePair , closeAnchor namePair ]
      )
  in
    List.map render (D.keys model.bufferMap)


{-| List item for joining new buffer.

```elm
relatedMsgs : List Msg
relatedMsgs == [ CreateBuffer, TypeNewChannelName ]
```
-}
newBufferItem : Model -> Html Msg
newBufferItem model =
  let
    newChannelName = getNewChannelName model model.currentServerName
  in
    li [ class "buffer-item new-buffer" ]
      [ form [ id "new-buffer-form", onSubmit <| CreateBuffer model.currentServerName ]
        [ input
          [ id "new-buffer-text"
          , placeholder "채널 이름"
          , autocomplete False
          , value newChannelName
          , onInput <| TypeNewChannelName model.currentServerName
          ]
          []
        , input [ id "new-buffer-submit", type_ "submit", value "Join" ] []
        ]
      ]


{-| Div showing information about the current buffer, including logs and new line form.
-}
currentBufferDiv : Model -> Html Msg
currentBufferDiv model =
  div [ id "current-buffer" ]
    [ currentBufferInfoDiv model
    , logsList model
    , newLineForm model
    ]


{-| Div showing information, that is, server name and channel name, for the current buffer.
-}
currentBufferInfoDiv : Model -> Html Msg
currentBufferInfoDiv model =
  let
    currentPositionText = model.currentServerName ++ " | " ++ model.currentChannelName
  in
    div [ id "current-buffer-info" ]
      [ text currentPositionText ]


{-| List showing the current buffer's logs.
-}
logsList : Model -> Html Msg
logsList model =
  let
    currentNamePair = ( model.currentServerName, model.currentChannelName )

    currentBuffer = getBuffer model currentNamePair
  in
    ul [ id "logs" ]
      (currentBuffer.lines
        |> List.map (\line -> li [] [ text ("<@" ++ line.nick ++ "> " ++ line.text) ])
      )


{-| Form for typing new line for the current buffer.

```elm
relatedMsgs : List Msg
relatedMsgs == [ SendLine, TypeNewLine ]
```
-}
newLineForm : Model -> Html Msg
newLineForm model =
  let
    currentNamePair = ( model.currentServerName, model.currentChannelName )

    currentBuffer = getBuffer model currentNamePair

    currentNick = getNick model model.currentServerName
  in
    form [ id "new-line-form", onSubmit SendLine ]
      [ label [ id "new-line-label" ] [ text currentNick ]
      , input
        [ id "new-line-text"
        , value currentBuffer.newLine
        , placeholder "메세지를 입력하세요"
        , autocomplete False
        , onInput TypeNewLine
        ]
        []
      , input [ id "new-line-submit", type_ "submit", value "전송" ] []
      ]
