module App exposing (..)

import String exposing (isEmpty)
import Html exposing (..)
import Html.Events exposing (onSubmit, onInput)
import Html.Attributes exposing (id, class, type_, placeholder, value)

main =
  Html.beginnerProgram {
    model = model,
    view = view,
    update = update
  }


-- Model
type alias Message =
  {
    nick : String,
    text : String
  }
type alias Model =
  {
    logs : List Message,
    nick : String,
    typing : String
  }

model : Model
model = Model [] "김젼" ""


-- Update
type Action = SendMessage
            | Typing String

update : Action -> Model -> Model
update msg model = case msg of
  SendMessage ->
    if isEmpty model.typing
    then model
    else { model |
      typing = "",
      logs = model.logs ++ [Message model.nick model.typing]
    }
  Typing msg -> { model | typing = msg }


-- View
view : Model -> Html Action
view model =
  div [ id "openirc" ] [
    ul [] (
      List.map (\msg ->
        li [] [text ("<@" ++ msg.nick ++ "> " ++ msg.text)]
      ) model.logs
    ),
    form [onSubmit SendMessage] [
      p [] [
        label [] [text "김젼"],
        input [value model.typing, placeholder "Hi!", onInput Typing] [],
        input [type_ "submit", value "전송"] []
      ]
    ]
  ]
