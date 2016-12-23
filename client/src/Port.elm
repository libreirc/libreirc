port module Port exposing
  (
    MqttPayload,
    publishMsg,
    subscribeMsg
  )
{-| A module that defines the ports that communicate with the outside js world.

###### References
- https://guide.elm-lang.org/interop/javascript.html#ports

-}

import Model exposing (NamePair, Line)


{-| Type which will be sent across elm-js boundary -}
type alias MqttPayload =
  {
    namePair : NamePair,
    line : Line
  }

{-| Port for publishing MQTT messages. -}
port publishMsg : MqttPayload -> Cmd msg

{-| Port for subscribing MQTT messages. -}
port subscribeMsg : (MqttPayload -> msg) -> Sub msg