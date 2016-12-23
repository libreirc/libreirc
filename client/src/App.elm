module App exposing (main)
{-| Elm module for OpenIRC client-side codes

Most of the OpenIRC client-side code is written in Elm. Only a small part of the
codes like communicating with outside world using MQTT.js is written in
Javascript. -}

import Html exposing (Html)
-- Local modules
import Model exposing (model)
import View exposing (view)
import Update exposing (update)
import Subscriptions exposing (subscriptions)


{-| Entry point for OpenIRC Elm codes -}
main : Program Never Model.Model Update.Msg
main = Html.program
  {
    init = (model, Cmd.none),
    view = view,
    update = update,
    subscriptions = subscriptions
  }
