module Update exposing (Msg(..), update)
{-| This module includes all update-related part of OpenIRC.

# Definitions

@docs Msg, cmdScrollToBottom

# Main update function

@docs update

# Helper functions

@docs updateBufferMap, updateNewChannelName, updateServerBuffer, isServerBuffer, isValidNewBuffer
-}

import String exposing (isEmpty, startsWith)
import Dict exposing (Dict)
import Dict as D
import Task exposing (Task)
import Dom.Scroll exposing (toBottom)
-- Local modules
import Model exposing (..)
import Port


{-| Collection of all msg used inside OpenIRC.

```elm
case Msg of
  -- msg regarding a new line in currently selected buffer
  SendLine            -- Send currently typed line by TypeNewLine.
                      -- You can think of this as 'typing enter.'

  TypeNewLine         -- Type a text in input for new line, at the
                      -- bottom of the current buffer

  -- msg regarding creating(joining to) a new buffer
  TypeNewChannelName  -- Type a text in input for new channel name, at the sidebar.

  CreateBuffer        -- Create(join to) a new buffer inside a server.
                      -- Name of the channel being created is current
                      -- server's `newChannelName`.

  -- msg used for changing curerntly selected buffer
  ChangeBuffer        -- Change the currently selected buffer to a specified buffer.

  -- msg used for closing(quitting from) a buffer
  CloseBuffer         -- Close(quit from) a specified buffer.

  -- msg doing nothing (this is needed because of the `update` function's required type signature)
  Noop                -- Do nothing.
```
-}
type Msg
  = SendLine
  | ReceiveLine Port.Payload
  | TypeNewLine String
  | TypeNewChannelName ServerName ChannelName
  | CreateBuffer ServerName
  | ChangeBuffer NamePair
  | CloseBuffer NamePair
  | Noop


{-| Main update function. This should be splitted into smaller functions in the future.
-}
update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
  let
    -- Currently selected server name, channel name pair
    currentNamePair = ( model.currentServerName, model.currentChannelName )

    -- Currently selected buffer
    currentBuffer = getBuffer model currentNamePair

    -- Current nick
    currentNick = getNick model model.currentServerName
  in
    case msg of
      SendLine ->
        -- Any SendLine to a server buffer is considered as an error for now.
        if isServerBuffer currentNamePair then
          let
            errorLog : Line
            errorLog = Line "ERROR" "You cannot send a line to the server buffer." Completed

            -- Add a error line to `lines` of current buffer, and set `newLine` of it to empty string.
            newBuffer = { currentBuffer | newLine = "" , lines = currentBuffer.lines ++ [ errorLog ] }
          in
            ( { model | serverInfoMap = updateServerBuffer model.serverInfoMap model.currentServerName newBuffer }
            , Cmd.none )

        -- If new line is empty, do nothing.
        else if isEmpty currentBuffer.newLine then
          ( model, Cmd.none )

        else
          -- Otherwise, send a line and scroll the log to the bottom.
          let
            -- Make new line
            newLine : Line
            newLine = {
              nick = currentNick,
              text = currentBuffer.newLine,
              status = Transmitting model.session.counter
            }

            -- Add a typed line to `lines` of current buffer, and set `newLine` of it to empty string.
            newBuffer = { currentBuffer | newLine = "", lines = currentBuffer.lines ++ [newLine] }
            -- Updated model
            newModel : Model
            newModel = { model |
              bufferMap = updateBufferMap model.bufferMap currentNamePair newBuffer,
              session = let session = model.session
                        in { session | counter = session.counter + 1 }
            }

            -- Publish the message to the MQTT broker
            cmd = Port.publishMsg {
              namePair = currentNamePair,
              line = newLine
            }
          in
            (newModel, cmd)

      ReceiveLine payload ->
        let
          -- TODO: 자기가 보낸 메세지 무시하는거 필요함

          -- Buffer to add the message
          targetBuffer = getBuffer model payload.namePair
          -- Updated buffer
          newBuffer = { targetBuffer | lines = targetBuffer.lines ++ [payload.line] }
          -- Updated model
          newModel = { model | bufferMap = updateBufferMap model.bufferMap payload.namePair newBuffer }

          -- Scroll to the bottom
          cmd = cmdScrollToBottom
        in
          (newModel, cmd)

      TypeNewLine typedNewLine ->
        let
          newBuffer = { currentBuffer | newLine = typedNewLine }
        in
          -- Currently selected buffer is a server buffer, so update `serverInfoMap`
          if isServerBuffer currentNamePair then
            ( { model | serverInfoMap = updateServerBuffer model.serverInfoMap model.currentServerName newBuffer }
            , Cmd.none )

          -- Currently selected buffer is not a server buffer, so update `bufferMap`
          else
            ( { model | bufferMap = updateBufferMap model.bufferMap currentNamePair newBuffer }, Cmd.none )

      TypeNewChannelName serverName newChannelName ->
        -- Updated `newChannelName` of corresponding server in `serverInfoMap`
        ( { model | serverInfoMap = updateNewChannelName model.serverInfoMap serverName newChannelName }
        , Cmd.none )

      CreateBuffer serverName ->
        let
          -- `newChannelName` of corresponding server, which is set with `TypeNewChannelName` msg.
          newChannelName = getNewChannelName model serverName

          -- Buffer map with the newly created buffer.
          updatedBufferMap = updateBufferMap model.bufferMap ( serverName, newChannelName ) (Buffer [] "")

          -- ServerInfo map with empty newChannelName for the server.
          updatedServerInfoMap = updateNewChannelName model.serverInfoMap serverName ""

          -- Updated model reflecting all related changes.
          updatedModel = { model | bufferMap = updatedBufferMap, serverInfoMap = updatedServerInfoMap }
        in
          -- If new buffer can be created, add it and switch to the newly created buffer.
          if isValidNewBuffer model ( serverName, newChannelName ) then
            update (ChangeBuffer ( serverName, newChannelName )) updatedModel

          -- If new buffer cannot be created, do nothing. Error notification logic should be added.
          else
            ( model, Cmd.none )

      ChangeBuffer ( newServerName, newChannelName ) ->
        ( { model | currentServerName = newServerName, currentChannelName = newChannelName }
        , cmdScrollToBottom -- Always scroll to bottom after a buffer switch.
        )

      CloseBuffer closingNamePair ->
        -- User cannot delete the server buffer (for now)
        if isServerBuffer closingNamePair then
          ( model, Cmd.none )
        else
          let
            -- Remaining bufferMap after closing the buffer.
            remainingBufferMap =
              model.bufferMap
                |> D.filter (\namePair _ -> namePair /= closingNamePair)

            -- Remaining name pairs after closing the buffer.
            remainingNamePairs = D.keys remainingBufferMap

            -- Name pair identifying next buffer to switch after closing the buffer
            ( nextServerName, nextChannelName ) =
              -- If currently selected buffer is not closed, keep the buffer selected
              if ( model.currentServerName, model.currentChannelName ) /= closingNamePair then
                ( model.currentServerName, model.currentChannelName )

              -- Otherwise, just choose the first buffer from remainingBufferMap
              else
                case List.head <| remainingNamePairs of
                  Just namePair ->
                    namePair

                  -- If there is no buffer opened, there's an error.
                  -- TODO: replace this to indicate that no buffer is open.
                  Nothing ->
                    ( "InitServer", "ERROR" )

            -- Updated model reflecting all related changes.
            updatedModel =
              { model | bufferMap = remainingBufferMap }
          in
            update (ChangeBuffer ( nextServerName, nextChannelName )) updatedModel

      Noop ->
        ( model, Cmd.none )


{-| Cmd which scrolls the currently selected buffer's log DOM node to the bottom.
-}
cmdScrollToBottom : Cmd Msg
cmdScrollToBottom =
  Task.attempt (\_ -> Noop) <| toBottom "logs"

{-| Helper function for updating `BufferMap`. Takes 1. Old bufferMap, 2. Dict key (name pair), 3. Dict value (buffer).
Returns a new bufferMap, with value for a given key is updated to a given value.

```elm
oldBufferMap : BufferMap

namePairForNewBuffer : NamePair

newBuffer : Buffer

newBufferMap : BufferMap

updateBufferMap oldBufferMap namePairForNewBuffer newBuffer == newBufferMap
```
-}
updateBufferMap : BufferMap -> NamePair -> Buffer -> BufferMap
updateBufferMap bufferMap namePair newBuffer =
  D.insert namePair newBuffer bufferMap


{-| Helper function for updating `ServerInfoMap`. Takes 1. Old serverInfoMap, 2. Dict key (server name), 3. Dict value
(new channel name). Returns a new serverInfoMap, with value for a given key is updated to a given value.

```elm
oldServerInfoMap : ServerInfoMap

serverName : ServerName

newChannelName : ChannelName

newServerInfoMap : ServerInfoMap

updateNewChannelName oldServerInfoMap serverName newChannelName == newServerInfoMap
```
-}
updateNewChannelName : ServerInfoMap -> ServerName -> ChannelName -> ServerInfoMap
updateNewChannelName oldServerInfoMap serverName newChannelName =
  let
    serverInfo =
      -- Check if serverName is a key of oldServerInfoMap.
      case D.get serverName oldServerInfoMap of
        Just serverInfo ->
          serverInfo

        Nothing ->
          ServerInfo "ERROR" "" errorBuffer

  in
    D.insert serverName { serverInfo | newChannelName = newChannelName } oldServerInfoMap


{-| Helper function for updating `ServerInfoMap`. Takes 1. Old serverInfoMap, 2. Dict key (server name), 3. Dict value
(new channel name). Returns a new serverInfoMap, with value for a given key is updated to a given value.

```elm
oldServerInfoMap : ServerInfoMap

serverName : ServerName

newServerBuffer : Buffer

newServerInfoMap : ServerInfoMap

updateNewChannelName oldServerInfoMap serverName newChannelName == newServerInfoMap
```
-}
updateServerBuffer : ServerInfoMap -> ServerName -> Buffer -> ServerInfoMap
updateServerBuffer oldServerInfoMap serverName newServerBuffer =
  let
    serverInfo =
      -- Check if serverName is a key of oldServerInfoMap.
      case D.get serverName oldServerInfoMap of
        Just serverInfo ->
          serverInfo

        Nothing ->
          ServerInfo "ERROR" "" errorBuffer

  in
    D.insert serverName { serverInfo | serverBuffer = newServerBuffer } oldServerInfoMap

{-| Helper function for checking whether given name pair is for a server buffer or not.
-}
isServerBuffer : NamePair -> Bool
isServerBuffer ( _, channelName ) =
  channelName == serverBufferKey


{-| Helper function for checking a name pair is valid for a new buffer.
-}
isValidNewBuffer : Model -> NamePair -> Bool
isValidNewBuffer model ( serverName, newChannelName ) =
  not <| -- If any of conditions below is satisfied, it's not a valid name pair.
    D.member ( serverName, newChannelName ) model.bufferMap -- Corresponding buffer already exists
    || isEmpty newChannelName                 -- New channel name is empty
    || not (startsWith "#" newChannelName)          -- New channel name violate channel name convention
