module App exposing (..)

import String exposing (dropRight)
import Html exposing (..)
import Html.Events exposing (onClick, onInput)
import Html.Attributes exposing (id, class, placeholder, value)

main = Html.beginnerProgram {
  model = model,
  view = view,
  update = update }


-- Model
type alias Model = {
  logs : List String,
  typing : String }

model = Model [] ""


-- Update
type Msg
  = Message
  | Typing String

update : Msg -> Model -> Model
update msg model = case msg of
  Message     -> { model | typing = "", logs = model.logs ++ [model.typing] }
  Typing msg  -> { model | typing = msg }


-- View
view : Model -> Html Msg
view model = div [ id "openirc" ] [
  ul [] (
    List.map (\elem ->
      li [] [text elem]
    ) model.logs
  ),
  span [] [ text "김젼" ],
  input [ value model.typing, placeholder "Hi!", onInput Typing ] [],
  button [ onClick Message ] [ text "+" ] ]
