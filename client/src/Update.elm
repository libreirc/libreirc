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
                        -- If new line is empty, do nothing
                        ( model, Cmd.none )
                    else
                        -- Otherwise, send a line and scroll the log to the bottom
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

                    -- If any of conditions below is satisfied, it's not a valid name for a buffer
                    isValidBufferName =
                        not <|
                            -- Already exists
                            D.member ( serverName, newChannelName ) model.bufferMap
                                || -- Empty new channel name
                                   isEmpty newChannelName
                                || -- Violate channel name convention
                                   not (startsWith "#" newChannelName)

                    -- Buffer map with the newly created buffer
                    updatedBufferMap =
                        updateBufferMap model.bufferMap ( serverName, newChannelName ) (Buffer [] "")

                    -- ServerInfo map with empty newChannelName for the server
                    updatedServerInfoMap =
                        updateNewChannelName model.serverInfoMap serverName ""

                    updatedModel =
                        { model | bufferMap = updatedBufferMap, serverInfoMap = updatedServerInfoMap }
                in
                    if isValidBufferName then
                        update (ChangeBuffer ( serverName, newChannelName )) updatedModel
                    else
                        -- Error notification logic should be added
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

                    remainingNamePairs =
                        D.keys remainingBufferMap

                    ( nextServerName, nextChannelName ) =
                        -- If currently selected buffer is not closed, keep the buffer selected
                        if ( model.currentServerName, model.currentChannelName ) /= closingNamePair then
                            ( model.currentServerName, model.currentChannelName )
                        else
                            -- Otherwise, just choose the first buffer from remainingBufferMap
                            case List.head <| remainingNamePairs of
                                Just namePair ->
                                    namePair

                                Nothing ->
                                    ( "InitServer", "ERROR" )

                    updatedModel =
                        { model | bufferMap = remainingBufferMap }
                in
                    update (ChangeBuffer ( nextServerName, nextChannelName )) updatedModel

            Noop ->
                ( model, Cmd.none )


{-| Cmd which scrolls the DOM node to the bottom
-}
cmdScrollToBottom : Cmd Msg
cmdScrollToBottom =
    Task.attempt (\_ -> Noop) <| toBottom "logs"


updateBufferMap : BufferMap -> ( ServerName, ChannelName ) -> Buffer -> BufferMap
updateBufferMap bufferMap namePair newBuffer =
    D.insert namePair newBuffer bufferMap


updateNewChannelName : ServerInfoMap -> ServerName -> ChannelName -> ServerInfoMap
updateNewChannelName serverInfoMap serverName newChannelName =
    let
        serverInfo =
            case D.get serverName serverInfoMap of
                Just serverInfo ->
                    serverInfo

                Nothing ->
                    ServerInfo "ERROR" "" errorBuffer

        updatedServerInfoMap =
            D.insert serverName { serverInfo | newChannelName = newChannelName } serverInfoMap
    in
        updatedServerInfoMap
