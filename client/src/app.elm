module App exposing (..)

import String exposing (isEmpty)
import Html exposing (..)
import Html.Events exposing (onSubmit, onInput, onClick)
import Html.Attributes exposing (id, class, type_, placeholder, value, autocomplete)
import Dict exposing (Dict)
import Dict as D

import Task exposing (Task)
import Dom.Scroll exposing (toBottom)


main =
  Html.program {
    init = ( model, Cmd.none ),
    view = view,
    update = update,
    subscriptions = \_ -> Sub.none
  }


-- Model
type alias Line =
  {
    nick : String,
    text : String
  }

type alias Channel =
  {
    logs : List Line,
    newLine : String
  }

type alias Model =
  {
    nick : String,
    currentName : String,
    newName : String,
    channels : Dict String Channel
  }

model : Model
model = Model "알파카" "#a" "" (D.fromList [
  ("#a", Channel [] ""),
  ("#b", Channel [] ""),
  ("#c", Channel [] "")
  ])

getCurrentChannel : Model -> Channel
getCurrentChannel model =
  case D.get model.currentName model.channels of
    Nothing -> Channel [Line "NOTICE" "Currently not in a (valid) channel."] ""
    Just channel -> channel


-- Update
type Msg = SendLine
         | TypeNewLine String
         | TypeNewName String
         | CreateChannel
         | ChangeChannel String
         | CloseChannel String
         | Noop

update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
  let currentChannel = getCurrentChannel model in
  case msg of
    SendLine ->
        if isEmpty currentChannel.newLine
        then ( model, Cmd.none )
        else (
          updateCurrentChannel model { currentChannel | newLine = "",
          logs = currentChannel.logs ++ [Line model.nick currentChannel.newLine]
          }, Task.attempt (\_ -> Noop) (toBottom "logs")
        )
    TypeNewLine msg ->
      (updateCurrentChannel model { currentChannel | newLine = msg }, Cmd.none)
    TypeNewName msg ->
      ( { model | newName = msg }, Cmd.none )
    CreateChannel ->
      if (D.member model.newName model.channels || model.newName == "")
      then ( model, Cmd.none ) {- Error notification logic should be added -}
      else (
        { model
        | channels = (D.insert model.newName (Channel [] "") model.channels), newName = ""
        }, Task.perform identity (Task.succeed (ChangeChannel model.newName))
        )
    ChangeChannel name ->
      ( { model | currentName = name }, Task.attempt (\_ -> Noop) (toBottom "logs") )
    CloseChannel name ->
      let
        remainingChannels = D.filter (\channelName _ -> channelName /= name) model.channels
        newCurrentName =
          case List.head (D.keys remainingChannels) of
            Just newCurrentName -> newCurrentName
            Nothing -> ""
      in
        ( { model | channels = remainingChannels }
          , Task.perform identity (Task.succeed (ChangeChannel newCurrentName)))
    Noop -> ( model, Cmd.none )

updateCurrentChannel : Model -> Channel -> Model
updateCurrentChannel model updatedCurrentChannel =
  { model
  | channels = D.insert model.currentName updatedCurrentChannel model.channels }


-- View
view : Model -> Html Msg
view model =
  let currentChannel = getCurrentChannel model in
  div [ id "openirc" ] [
    div [id "channels" ] [
      ul [ id "channel-list" ] (
        [li [class "channel-item server-name"] [text "서버 A"]] ++
        (List.map (\name ->
          li [class (if name == model.currentName
          then "channel-item channel-name channel-selected"
          else "channel-item channel-name"), onClick (ChangeChannel name)] [
            text name,
            a [class "channel-close", onClick (CloseChannel name)] [text "✘"]
          ]
        ) (D.keys model.channels)) ++
        [li [class "channel-item new-channel"] [
          form [id "new-channel-form", onSubmit CreateChannel] [
            input [id "new-channel-text", placeholder "채널 이름",
                autocomplete False, value model.newName, onInput TypeNewName] [],
            input [id "new-channel-submit", type_ "submit", value "Join"] []
          ]
        ]]
      )
    ],
    div [id "current-channel"] [
      ul [ id "logs" ] (
        List.map (\msg ->
          li [] [text ("<@" ++ msg.nick ++ "> " ++ msg.text)]
        ) currentChannel.logs
      ),
      form [ id "new-line-form", onSubmit SendLine] [
        label [id "new-line-label"] [text model.nick],
        input [id "new-line-text", value currentChannel.newLine,
            placeholder "메세지를 입력하세요", autocomplete False,
            onInput TypeNewLine] [],
        input [id "new-line-submit", type_ "submit", value "전송"] []
      ]
    ]
  ]
