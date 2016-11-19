module App exposing (..)

import Html exposing (Html, button, div, text)
import Html.App as App
import Html.Events exposing (onClick)
import Html.Attributes exposing (class)

main = App.beginnerProgram {
  model = 0,
  view = view,
  update = update }

type Msg = Increment | Decrement

update msg model = case msg of
  Increment -> model + 1
  Decrement -> model - 1

view model = div [] [
  button [ onClick Decrement ] [ text "-" ],
  div [ class "counter" ] [ text (toString model) ],
  button [ onClick Increment ] [ text "+" ] ]
