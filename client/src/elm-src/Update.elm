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
                        ( { model | bufferMap = updateBufferMap model.bufferMap currentNamePair newBuffer }, cmdScrollToBottom )

            TypeNewLine typedNewLine ->
                let
                    newBuffer =
                        { currentBuffer | newLine = typedNewLine }
                in
                    ( { model | bufferMap = updateBufferMap model.bufferMap currentNamePair newBuffer }, Cmd.none )

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
                    -- Buffer map with the newly created buffer
                    updatedBufferMap =
                        updateBufferMap model.bufferMap ( serverName, newChannelName ) (Buffer [] "")

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
                , cmdScrollToBottom
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

            Noop ->
                ( model, Cmd.none )


{-| Cmd which scrolls the DOM node to the bottom
-}
cmdScrollToBottom : Cmd Msg
cmdScrollToBottom =
    Task.attempt (\_ -> Noop) <| toBottom "logs"


updateBufferMap : Dict ( ServerName, ChannelName ) Buffer -> ( ServerName, ChannelName ) -> Buffer -> Dict ( ServerName, ChannelName ) Buffer
updateBufferMap bufferMap namePair newBuffer =
    D.insert namePair newBuffer bufferMap


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
