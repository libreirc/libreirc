module Update exposing (..)

import String exposing (isEmpty, startsWith)
import Dict exposing (Dict)
import Dict as D
import Task exposing (Task)
import Dom.Scroll exposing (toBottom)
import Model exposing (..)


-- Update


type Msg
    = SendLine
    | TypeNewLine String
    | TypeNewChannelName ServerName ChannelName
    | CreateBuffer ServerName
    | ChangeBuffer ( ServerName, ChannelName )
    | CloseBuffer ( ServerName, ChannelName )
    | Noop


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    let
        currentNamePair =
            ( model.currentServerName, model.currentChannelName )

        currentBuffer =
            getBuffer model currentNamePair

        currentNick =
            getNick model model.currentServerName
    in
        case msg of
            SendLine ->
                let
                    newLog =
                        Line currentNick currentBuffer.newLine

                    newBuffer =
                        { currentBuffer | newLine = "", lines = currentBuffer.lines ++ [ newLog ] }
                in
                    if isEmpty currentBuffer.newLine then
                        ( model, Cmd.none )
                    else
                        ( updateBuffer model currentNamePair newBuffer, Task.attempt (\_ -> Noop) <| toBottom "logs" )

            TypeNewLine typedNewLine ->
                let
                    newBuffer =
                        { currentBuffer | newLine = typedNewLine }
                in
                    ( updateBuffer model currentNamePair newBuffer, Cmd.none )

            TypeNewChannelName serverName newChannelName ->
                ( { model
                    | serverInfoMap = updateNewChannelName model.serverInfoMap serverName newChannelName
                  }
                , Cmd.none
                )

            CreateBuffer serverName ->
                let
                    newChannelName =
                        getNewChannelName model serverName

                    isValidBufferName =
                        not
                            (D.member ( serverName, newChannelName ) model.bufferMap
                                || isEmpty newChannelName
                                || not (startsWith "#" newChannelName)
                            )

                    newBufferMap =
                        D.insert ( serverName, newChannelName ) (Buffer [] "") model.bufferMap

                    updatedServerInfoMap =
                        updateNewChannelName model.serverInfoMap serverName ""
                in
                    if isValidBufferName then
                        ( { model | bufferMap = newBufferMap, serverInfoMap = updatedServerInfoMap }
                        , Task.perform identity (Task.succeed <| ChangeBuffer ( serverName, newChannelName ))
                        )
                    else
                        {- Error notification logic should be added -}
                        ( model, Cmd.none )

            ChangeBuffer ( newServerName, newChannelName ) ->
                ( { model | currentServerName = newServerName, currentChannelName = newChannelName }
                , Task.attempt (\_ -> Noop) (toBottom "logs")
                )

            CloseBuffer closingNamePair ->
                let
                    remainingBufferMap =
                        model.bufferMap
                            |> D.filter (\namePair _ -> namePair /= closingNamePair)

                    ( nextServerName, nextChannelName ) =
                        if ( model.currentServerName, model.currentChannelName ) /= closingNamePair then
                            ( model.currentServerName, model.currentChannelName )
                        else
                            case List.head <| D.keys remainingBufferMap of
                                Just namePair ->
                                    namePair

                                Nothing ->
                                    ( "InitServer", "ERROR" )
                in
                    ( { model
                        | bufferMap = remainingBufferMap
                        , currentServerName = nextServerName
                        , currentChannelName = nextChannelName
                      }
                    , Task.perform identity <| Task.succeed <| ChangeBuffer ( nextServerName, nextChannelName )
                    )

            Noop ->
                ( model, Cmd.none )


updateBuffer : Model -> ( ServerName, ChannelName ) -> Buffer -> Model
updateBuffer model namePair newBuffer =
    { model | bufferMap = D.insert namePair newBuffer model.bufferMap }


updateNewChannelName : Dict ServerName ServerInfo -> ServerName -> ChannelName -> Dict ServerName ServerInfo
updateNewChannelName serverInfoMap serverName newChannelName =
    let
        serverInfo =
            case D.get serverName serverInfoMap of
                Just serverInfo ->
                    serverInfo

                Nothing ->
                    ServerInfo "ERROR" ""

        updatedServerInfoMap =
            D.insert serverName { serverInfo | newChannelName = newChannelName } serverInfoMap
    in
        updatedServerInfoMap
