module App exposing (..)

import String exposing (isEmpty, startsWith)
import Html exposing (..)
import Html.Events exposing (onSubmit, onInput, onClick)
import Html.Attributes exposing (id, class, type_, placeholder, value, autocomplete)
import Dict exposing (Dict)
import Dict as D
import Tuple exposing (first, second)
import Task exposing (Task)
import Dom.Scroll exposing (toBottom)
import Model exposing (model)
import View exposing (view)
import Update exposing (update)


main =
    Html.program
        { init = ( model, Cmd.none )
        , view = view
        , update = update
        , subscriptions = \_ -> Sub.none
        }
