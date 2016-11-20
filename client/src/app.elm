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
type alias Model =
  {
    logs : List String,
    typing : String
  }

model = Model [] ""


-- Update
type Action = Message
         | Typing String

update : Action -> Model -> Model
update msg model = case msg of
  Message ->
    if isEmpty model.typing
    then model
    else { model | typing = "", logs = model.logs ++ [model.typing] }
  Typing msg -> { model | typing = msg }


-- View
view : Model -> Html Action
view model =
  div [ id "openirc" ] [
    ul [] (
      List.map (\elem ->
        li [] [text elem]
      ) model.logs
    ),
    form [onSubmit Message] [
      p [] [
        label [] [text "김젼"],
        input [value model.typing, placeholder "Hi!", onInput Typing] [],
        input [type_ "submit", value "전송"] []
      ]
    ]
  ]
