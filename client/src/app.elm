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
    nick : String,
    logs : List Line,
    typing : String
  }

type alias Model =
  {
    currentName : String,
    channels : Dict String Channel
  }

model : Model
model = Model "#a" (D.fromList [
  ("#a", Channel "알파카" [] ""),
  ("#b", Channel "고양이" [] ""),
  ("#c", Channel "펭귄" [] "")
  ])

getCurrentChannel : Model -> Channel
getCurrentChannel model =
  case D.get model.currentName model.channels of
    Nothing -> Channel "#error" [Line "error" "no such channel"] ""
    Just channel -> channel


-- Update
type Msg = SendLine
         | Typing String
         | ChangeChannel String
         | Noop

update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
  let currentChannel = getCurrentChannel model in
  case msg of
    SendLine ->
        if isEmpty currentChannel.typing
        then ( model, Cmd.none )
        else (
          updateCurrentChannel model { currentChannel | typing = "",
          logs = currentChannel.logs ++ [Line currentChannel.nick currentChannel.typing]
          }, Task.attempt (\_ -> Noop) (toBottom "logs")
        )
    Typing msg ->
      (updateCurrentChannel model { currentChannel | typing = msg }, Cmd.none)
    ChangeChannel name ->
      ( { model | currentName = name }, Task.attempt (\_ -> Noop) (toBottom "logs") )
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
        li [class "channel-item server-name"] [text "서버 A"] ::
        (List.map (\name ->
          li [class "channel-item channel-name", onClick (ChangeChannel name)] [text name]
        ) (D.keys model.channels))
      )
    ],
    div [id "current-channel"] [
      ul [ id "logs" ] (
        List.map (\msg ->
          li [] [text ("<@" ++ msg.nick ++ "> " ++ msg.text)]
        ) currentChannel.logs
      ),
      form [ id "typing-form", onSubmit SendLine] [
        label [id "typing-label"] [text currentChannel.nick],
        input [id "typing-text", value currentChannel.typing,
            placeholder "메세지를 입력하세요", autocomplete False,
            onInput Typing] [],
        input [id "typing-submit", type_ "submit", value "전송"] []
      ]
    ]
  ]
