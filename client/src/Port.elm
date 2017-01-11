port module Port exposing
  (
    Payload,
    publishMsg,
    subscribeMsg
  )
{-| A module that defines the ports that communicate with the outside js world.

# Low-level functions

@docs MqttPayload, onMessage, newMessage

# High-level interfaces

@docs Payload, publishMsg, subscribeMsg

###### References
- https://guide.elm-lang.org/interop/javascript.html#ports

-}

import Tuple exposing (first, second)
import Model exposing (NamePair, Line, Session)

-- Low-level functions
{-| Type which will be actually sent across elm-js boundary.

###### Reference
- https://guide.elm-lang.org/interop/javascript.html#customs-and-border-protection

-}
type alias MqttPayload =
  {
    namePair : NamePair,
    line: {
      nick: String,
      text: String,
      status: Maybe Float
    },
    session: (Int, Int)
  }

{-| Port for publishing MQTT messages. -}
port onMessage : MqttPayload -> Cmd msg

{-| Port for subscribing MQTT messages. -}
port newMessage : (MqttPayload -> msg) -> Sub msg


{-| Type which represents a single MQTT packet -}
type alias Payload =
  {
    namePair: NamePair,
    line: Line,
    session: Session
  }


{-| Port for publishing MQTT messages. -}
publishMsg : Payload -> Cmd msg
publishMsg payload =
  onMessage {
    namePair = payload.namePair,
    line = {
      nick = payload.line.nick,
      text = payload.line.text,
      status = case payload.line.status of
        Model.Transmitting tempId -> Just (toFloat tempId)
        Model.Completed -> Nothing
    },
    session = (payload.session.id, payload.session.counter)
  }

{-| Port for subscribing MQTT messages. -}
subscribeMsg : (Payload -> msg) -> Sub msg
subscribeMsg tagger =
  let
    convert : MqttPayload -> Payload
    convert mqtt = {
      namePair = mqtt.namePair,
      line = {
        nick = mqtt.line.nick,
        text = mqtt.line.text,
        status = case mqtt.line.status of
          Just tempId -> Model.Transmitting (round tempId)
          Nothing -> Model.Completed
      },
      session = {
        id = first mqtt.session,
        counter = second mqtt.session
      }
    }
  in newMessage (convert >> tagger)
