module Model exposing (..)

import Dict exposing (Dict)
import Dict as D


-- Model


type alias Line =
    { nick : String
    , text : String
    }


type alias Buffer =
    { lines : List Line
    , newLine : String
    }


type alias ServerInfo =
    { nick : String
    , newChannelName : ChannelName
    }


type alias ServerName =
    String


type alias ChannelName =
    String


type alias Model =
    { bufferMap : Dict ( ServerName, ChannelName ) Buffer
    , serverInfoMap : Dict ServerName ServerInfo
    , currentServerName : ServerName
    , currentChannelName : ChannelName
    }


model : Model
model =
    Model
        (D.fromList
            [ ( ( "InitServer", "#a" ), Buffer [] "" )
            , ( ( "InitServer", "#b" ), Buffer [] "" )
            , ( ( "InitServer", "#c" ), Buffer [] "" )
            ]
        )
        (D.fromList
            [ ( "InitServer", ServerInfo "InitNick" "" ) ]
        )
        "InitServer"
        "#a"


getBuffer : Model -> ( ServerName, ChannelName ) -> Buffer
getBuffer model namePair =
    case D.get namePair model.bufferMap of
        Nothing ->
            Buffer [ Line "NOTICE" "Currently not in a (valid) buffer." ] ""

        Just buffer ->
            buffer


getServerInfo : Model -> ServerName -> ServerInfo
getServerInfo model serverName =
    case D.get serverName model.serverInfoMap of
        Just serverInfo ->
            serverInfo

        Nothing ->
            ServerInfo "ERROR" ""


getNick : Model -> ServerName -> String
getNick model serverName =
    getServerInfo model serverName
        |> (.nick)


getNewChannelName : Model -> ServerName -> ChannelName
getNewChannelName model serverName =
    getServerInfo model serverName
        |> (.newChannelName)
