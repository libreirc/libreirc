module App exposing (..)

import String exposing (isEmpty)
import Html exposing (..)
import Html.Events exposing (onSubmit, onInput)
import Html.Attributes exposing (id, class, type_, placeholder, value)

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
type alias Model =
  {
    logs : List Line,
    nick : String,
    typing : String
  }

model : Model
model = Model [] "김젼" ""

-- Update
type Msg = SendLine
         | Typing String
         | Noop

update : Msg -> Model -> ( Model, Cmd Msg )
update msg model = case msg of
  SendLine ->
    if isEmpty model.typing
    then ( model, Cmd.none )
    else (
      { model |
      typing = "",
      logs = model.logs ++ [Line model.nick model.typing]
      },
      Task.attempt (\_ -> Noop) (toBottom "logs")
    )
  Typing msg -> ( { model | typing = msg }, Cmd.none )
  Noop -> ( model, Cmd.none )

-- View
view : Model -> Html Msg
view model =
  div [ id "openirc" ] [
    ul [ id "logs" ] (
      List.map (\msg ->
        li [] [text ("<@" ++ msg.nick ++ "> " ++ msg.text)]
      ) model.logs
    ),
    form [onSubmit SendLine] [
      label [] [text "김젼"],
      input [value model.typing, placeholder "메세지를 입력하세요", onInput Typing] [],
      input [type_ "submit", value "전송"] []
    ]
  ]
