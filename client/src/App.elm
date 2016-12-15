module App exposing (main)

import Html exposing (Html)
-- Local modules
import Model exposing (model)
import View exposing (view)
import Update exposing (update)


main : Program Never Model.Model Update.Msg
main =
    Html.program
        { init = ( model, Cmd.none )
        , view = view
        , update = update
        , subscriptions = \_ -> Sub.none
        }
