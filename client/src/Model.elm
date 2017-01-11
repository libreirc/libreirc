module Model exposing (..)
{-| This module includes all model-related part of OpenIRC.
Top-level model consists of four fields: bufferMap, serverInfoMap, currentServerName, currentChannelName.

# Definitions

@docs ServerName, ChannelName, NamePair, Line, Buffer, ServerInfo, BufferMap, ServerInfoMap, Model

# Constants

@docs model, errorBuffer, initialServerBuffer, serverBufferKey

# Getters

@docs getBuffer, getServerInfo, getNick, getNewChannelName, getServerBuffer

-}

import Array exposing (Array)
import Array as A
import Dict exposing (Dict)
import Dict as D

{-| Server name is a string -}
type alias ServerName = String

{-| Channel name is a string -}
type alias ChannelName = String

{-| A pair of a server name and a channel name -}
type alias NamePair = (ServerName, ChannelName)

{-| Type which indicates the status of single `Line`.

-   `Transmitting` means the `Line` is still being transmitted. The `String`
    value in the `Transmitting` constructor is the temporary unique identifier
    for uncompleted transmittion.

-   `Completed` means the `Line` is fully transmitted and finished the
    round-trip.

-}
type LineStatus = Transmitting Int
                | Completed

{-| Line consist of a nickname of the user, a text and status of the line.

```elm
line : Line
line = Line "User A" "My name is User A. Nice to meet you!"
```
-}
type alias Line =
  {
    nick: String,
    text: String,
    status: LineStatus
  }


{-| Buffer represents a single channel, joined by a user. It l
It has two fields: `lines`, which represents all available logs, and `newLine`, which represents a new line buffer that the
user has typed.

```elm
line : Line
line = Line "User A" "My name is User A. Nice to meet you!"

buffer : Buffer [ line ] "I'm typing this line"
```
-}
type alias Buffer =
  { lines : Array Line
  , newLine : String
  }


{- ServerInfo contains all the information of a user, related to a single server.
It has three fields: `nick`, current user's nickname, `newChannelName`, which represents the typed new channel name
the user is trying to join in this server, and `serverBuffer`, a special buffer dedicated to the use of server(e.g.
connection notification).

```elm
welcomeLine : Line
welcomeLine = Line "SERVER" "Welcome to server A."

serverBuffer : Buffer
serverBuffer = Buffer [ welcomeLine ] ""

serverInfo : ServerInfo
serverInfo = "User A" "" serverBuffer
```
-}
type alias ServerInfo =
  { nick : String
  , newChannelName : ChannelName
  , serverBuffer : Buffer
  }


{-| BufferMap is a dictionary mapping `NamePair` to corresponding `Buffer`.
Note that server buffer is not included in this.
-}
type alias BufferMap =
  Dict NamePair Buffer


{-| ServerInfoMap is a dictionary mapping `ServerName` to corresponding `ServerInfo`.
-}
type alias ServerInfoMap =
  Dict ServerName ServerInfo


{-| This type stores the information about a single MQTT connection.

The `id` is the random identifier created in the beginning of the program.

The `counter` represents the message counter of this session. Everytime you send
a new message, this counter goes up by one.

    Counter |       Action
    --------|-----------------
       0    | (Initial state)
            |  Send a message
       1    |
            |  Send a message
       2    |
            |  Send a message
       3    |

-}
type alias Session =
  {
    id: Int,
    counter: Int
  }


{-| TransmittingLineIndex is a dictionary mapping `Counter` to corresponding
index of a line in `Buffer.lines`. This is used for efficient status change of
line. -}
type alias TransmittingLineIndex =
  Dict Int Int


{-| Current model structure. The pair of `currentServerName` and `currentChannelName` acts as a key identifying
currently selected buffer. If a user is seeing server buffer, `currentChannelName` is set to `serverBufferKey`.
-}
type alias Model =
  {
    bufferMap: BufferMap,
    serverInfoMap: ServerInfoMap,
    currentServerName: ServerName,
    currentChannelName: ChannelName,
    session: Session,
    transmittingLineIndex: TransmittingLineIndex
  }



{-| Dummy model which will be used until the backend is implemented. -}
model : Model
model =
  Model
    (D.fromList
      [ ( ( "InitServer", "#a" ), Buffer A.empty "" )
      , ( ( "InitServer", "#b" ), Buffer A.empty "" )
      , ( ( "InitServer", "#c" ), Buffer A.empty "" )
      ]
    )
    (D.fromList
      [ ( "InitServer", ServerInfo "InitNick" "" <| initialServerBuffer "InitServer" ) ]
    )
    "InitServer"
    "#a"
    {
      id = 123456789, -- TODO: Randomize
      counter = 0
    }
    D.empty


{-| Buffer represnting that an error has occurred.
-}
errorBuffer : Buffer
errorBuffer =
  Buffer (A.fromList [ Line "NOTICE" "Currently not in a (valid) buffer." Completed]) ""


{- Dummy initial server buffer. This should be replaced as server-dependent buffer containing welcome message and etc.
-}
initialServerBuffer : ServerName -> Buffer
initialServerBuffer serverName =
  let
    welcomeMsg =
      "WELCOME TO " ++ serverName ++ " SERVER."
  in
    Buffer (A.fromList [ Line "WELCOME" welcomeMsg Completed ]) ""


{-| A constant used as `currentChannelName` when user is seeing server buffer.
-}
serverBufferKey : ChannelName
serverBufferKey =
  "Server Buffer"

{-| Receives a model and a name pair, returns a corresponding `Buffer`.

  getBuffer model ( "InitServer", "#a" ) == Buffer [] ""
-}
getBuffer : Model -> ( ServerName, ChannelName ) -> Buffer
getBuffer model ( serverName, channelName ) =
  if channelName == serverBufferKey then
    getServerBuffer model serverName
  else
    case D.get ( serverName, channelName ) model.bufferMap of
      Nothing ->
        errorBuffer

      Just buffer ->
        buffer

{-| Receives a model and a server name, returns a corresponding `ServerInfo`.

```elm
getServerInfo model "InitServer" == ServerInfo "InitNick" "" <| InitialServerBuffer "InitServer"
```
-}
getServerInfo : Model -> ServerName -> ServerInfo
getServerInfo model serverName =
  case D.get serverName model.serverInfoMap of
    Just serverInfo ->
      serverInfo

    Nothing ->
      ServerInfo "ERROR" "" errorBuffer


{-| Receives a model and a server name, returns a corresponding `nick`.

```elm
getNick model "InitServer" == "InitNick"
```
-}
getNick : Model -> ServerName -> String
getNick model serverName =
  getServerInfo model serverName
    |> (.nick)


{-| Receives a model and a server name, returns a corresponding `newChannelName`.

```elm
getNewChannelName model "InitServer" == ""
```
-}
getNewChannelName : Model -> ServerName -> ChannelName
getNewChannelName model serverName =
  getServerInfo model serverName
    |> (.newChannelName)


{-| Receives a model and a server name, returns a corresponding `serverBuffer`.

```elm
getServerBuffer model "InitServer" == InitialServerBuffer "InitServer"
```
-}
getServerBuffer : Model -> ServerName -> Buffer
getServerBuffer model serverName =
  getServerInfo model serverName
    |> (.serverBuffer)
