module App exposing (..)

import String exposing (isEmpty)
import Html exposing (..)
import Html.Events exposing (onSubmit, onInput)
import Html.Attributes exposing (id, class, type_, placeholder, value)

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
    currentChannel : String,
    channels : Dict String Channel
  }

model : Model
model = Model "#a" (D.fromList [
  ("#a", Channel "알파카" [] ""),
  ("#b", Channel "고양이" [] ""),
  ("#c", Channel "펭귄" [] "")
  ])


-- Update
type Msg = SendLine
         | Typing String
         | Noop

update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
  case msg of
    SendLine ->
        if D.isEmpty (
          D.filter (\name channel ->
            name == model.currentChannel && channel.typing /= "")
            model.channels
            )
        then ( model, Cmd.none )
        else (
          { model | channels =
            D.update model.currentChannel addLineToLogs model.channels
          },
          Task.attempt (\_ -> Noop) (toBottom "logs")
        )
    Typing msg -> (
      { model |
        channels =
          D.update model.currentChannel (handleTyping msg) model.channels
        }, Cmd.none)
    Noop -> ( model, Cmd.none )

addLineToLogs : Maybe Channel -> Maybe Channel
addLineToLogs mChannel = case mChannel of
  Nothing -> Nothing
  Just channel ->
    Just { channel |
      typing = "",
      logs = channel.logs ++ [Line channel.nick channel.typing]
      }

handleTyping : String -> (Maybe Channel -> Maybe Channel)
handleTyping msg = (\mChannel ->
  case mChannel of
    Nothing -> Nothing
    Just channel -> Just { channel | typing = msg }
  )

-- View
view : Model -> Html Msg
view model =
  let currentChannel =
      case (Dict.get model.currentChannel model.channels) of
        Nothing -> Channel "#error" [Line "error" "no such channel"] ""
        Just channel -> channel
  in
  div [ id "openirc" ] [
    ul [ id "logs" ] (
      List.map (\msg ->
        li [] [text ("<@" ++ msg.nick ++ "> " ++ msg.text)]
      ) currentChannel.logs
    ),
    form [onSubmit SendLine] [
      label [] [text currentChannel.nick],
      input [value currentChannel.typing, placeholder "메세지를 입력하세요", onInput Typing] [],
      input [type_ "submit", value "전송"] []
    ]
  ]
