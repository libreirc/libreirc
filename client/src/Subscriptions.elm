module Subscriptions exposing (..)
{-| A module that defines the ports that communicate with the outside js world.

###### References
- https://guide.elm-lang.org/interop/javascript.html#ports

-}

import Model exposing (Model)
import Update exposing (Msg(ReceivePayload))
import Port exposing (subscribeMsg)

subscriptions : Model -> Sub Msg
subscriptions _ = subscribeMsg ReceivePayload
