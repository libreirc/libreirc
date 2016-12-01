module App exposing (..)

import String exposing (isEmpty, startsWith)
import Html exposing (..)
import Html.Events exposing (onSubmit, onInput, onClick)
import Html.Attributes exposing (id, class, type_, placeholder, value, autocomplete)
import Dict exposing (Dict)
import Dict as D
import Tuple exposing (first, second)
import Task exposing (Task)
import Dom.Scroll exposing (toBottom)


main =
    Html.program
        { init = ( model, Cmd.none )
        , view = view
        , update = update
        , subscriptions = \_ -> Sub.none
        }



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



-- View


view : Model -> Html Msg
view model =
    div [ id "openirc" ]
        [ bufferListsDiv model
        , currentBufferDiv model
        ]


bufferListsDiv : Model -> Html Msg
bufferListsDiv model =
    div [ id "buffer-lists" ]
        [ ul [ class "buffer-list" ]
            ([ serverNameItem "서버 A" ] ++ bufferNameItems model ++ [ newBufferItem model ])
        ]


serverNameItem : ServerName -> Html Msg
serverNameItem name =
    li [ class "buffer-item server-name" ] [ text name ]


bufferNameItems : Model -> List (Html Msg)
bufferNameItems model =
    let
        itemClass namePair =
            if namePair == ( model.currentServerName, model.currentChannelName ) then
                "buffer-item buffer-name buffer-selected"
            else
                "buffer-item buffer-name"

        closeAnchor namePair =
            a [ class "buffer-close", onClick <| CloseBuffer namePair ] [ text "✘" ]

        render =
            (\namePair ->
                li
                    [ class <| itemClass namePair
                    , onClick <| ChangeBuffer namePair
                    ]
                    [ text <| second namePair, closeAnchor namePair ]
            )
    in
        List.map render (D.keys model.bufferMap)


newBufferItem : Model -> Html Msg
newBufferItem model =
    let
        newChannelName =
            getNewChannelName model model.currentServerName
    in
        li [ class "buffer-item new-buffer" ]
            [ form [ id "new-buffer-form", onSubmit <| CreateBuffer model.currentServerName ]
                [ input
                    [ id "new-buffer-text"
                    , placeholder "채널 이름"
                    , autocomplete False
                    , value newChannelName
                    , onInput <| TypeNewChannelName model.currentServerName
                    ]
                    []
                , input [ id "new-buffer-submit", type_ "submit", value "Join" ] []
                ]
            ]


currentBufferDiv : Model -> Html Msg
currentBufferDiv model =
    div [ id "current-buffer" ]
        [ logsList model
        , newLineForm model
        ]


logsList : Model -> Html Msg
logsList model =
    let
        currentNamePair =
            ( model.currentServerName, model.currentChannelName )

        currentBuffer =
            getBuffer model currentNamePair
    in
        ul [ id "logs" ]
            (currentBuffer.lines
                |> List.map (\line -> li [] [ text ("<@" ++ line.nick ++ "> " ++ line.text) ])
            )


newLineForm : Model -> Html Msg
newLineForm model =
    let
        currentNamePair =
            ( model.currentServerName, model.currentChannelName )

        currentBuffer =
            getBuffer model currentNamePair

        currentNick =
            getNick model model.currentServerName
    in
        form [ id "new-line-form", onSubmit SendLine ]
            [ label [ id "new-line-label" ] [ text currentNick ]
            , input
                [ id "new-line-text"
                , value currentBuffer.newLine
                , placeholder "메세지를 입력하세요"
                , autocomplete False
                , onInput TypeNewLine
                ]
                []
            , input [ id "new-line-submit", type_ "submit", value "전송" ] []
            ]
