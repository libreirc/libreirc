module App exposing (..)

import String exposing (isEmpty)
import Html exposing (..)
import Html.Events exposing (onSubmit, onInput, onClick)
import Html.Attributes exposing (id, class, type_, placeholder, value, autocomplete)
import Dict exposing (Dict)
import Dict as D
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


type alias Model =
    { bufferMap : Dict Int Buffer
    , bufferIdMap : Dict ( String, String ) Int
    , nickMap : Dict String String
    , currentBufferId : Int
    , currentServerName : String
    , newChannelName : String
    }


model : Model
model =
    Model
        (D.fromList
            [ ( 0, Buffer [] "" )
            , ( 1, Buffer [] "" )
            , ( 2, Buffer [] "" )
            ]
        )
        (D.fromList
            [ ( ( "InitServer", "#a" ), 0 )
            , ( ( "InitServer", "#b" ), 1 )
            , ( ( "InitServer", "#c" ), 2 )
            ]
        )
        (D.fromList
            [ ( "InitServer", "InitNick" ) ]
        )
        0
        "InitServer"
        ""


getCurrentBuffer : Model -> Buffer
getCurrentBuffer model =
    case D.get model.currentBufferId model.bufferMap of
        Nothing ->
            Buffer [ Line "NOTICE" "Currently not in a (valid) buffer." ] ""

        Just buffer ->
            buffer


getCurrentNick : Model -> String
getCurrentNick model =
    case D.get model.currentServerName model.nickMap of
        Nothing ->
            "ERROR"

        Just nick ->
            nick



-- Update


type Msg
    = SendLine
    | TypeNewLine String
    | TypeNewName String
    | CreateBuffer
    | ChangeBuffer Int
    | CloseBuffer Int
    | Noop


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    let
        currentBuffer =
            getCurrentBuffer model

        currentNick =
            getCurrentNick model
    in
        case msg of
            SendLine ->
                let
                    newLog =
                        Line currentNick currentBuffer.newLine

                    newCurrentBuffer =
                        { currentBuffer | newLine = "", lines = currentBuffer.lines ++ [ newLog ] }
                in
                    if isEmpty currentBuffer.newLine then
                        ( model, Cmd.none )
                    else
                        ( updateCurrentBuffer model newCurrentBuffer, Task.attempt (\_ -> Noop) <| toBottom "logs" )

            TypeNewLine msg ->
                ( updateCurrentBuffer model { currentBuffer | newLine = msg }
                , Cmd.none
                )

            TypeNewName msg ->
                ( { model | newChannelName = msg }
                , Cmd.none
                )

            CreateBuffer ->
                let
                    newBufferId =
                        case (List.maximum <| D.keys model.bufferMap) of
                            Just id ->
                                id + 1

                            Nothing ->
                                1

                    currentServerName =
                        model.currentServerName

                    newChannelName =
                        model.newChannelName

                    newBufferIdMap =
                        D.insert ( currentServerName, newChannelName ) newBufferId model.bufferIdMap

                    newBufferMap =
                        D.insert newBufferId (Buffer [] "") model.bufferMap
                in
                    if
                        (D.member ( currentServerName, newChannelName ) model.bufferIdMap
                            || isEmpty newChannelName
                        )
                    then
                        {- Error notification logic should be added -}
                        ( model, Cmd.none )
                    else
                        ( { model
                            | bufferIdMap = newBufferIdMap
                            , bufferMap = newBufferMap
                            , newChannelName = ""
                          }
                        , Task.perform identity (Task.succeed <| ChangeBuffer newBufferId)
                        )

            ChangeBuffer newBufferId ->
                ( { model | currentBufferId = newBufferId }
                , Task.attempt (\_ -> Noop) (toBottom "logs")
                )

            CloseBuffer closingBufferId ->
                let
                    remainingBufferMap =
                        model.bufferMap
                            |> D.filter (\bufferId _ -> bufferId /= closingBufferId)

                    remainingBufferIdMap =
                        model.bufferIdMap
                            |> D.filter (\_ bufferId -> bufferId /= closingBufferId)

                    newCurrentBufferId =
                        if model.currentBufferId /= closingBufferId then
                            model.currentBufferId
                        else
                            case List.head <| D.keys remainingBufferMap of
                                Just id ->
                                    id

                                Nothing ->
                                    0
                in
                    ( { model
                        | bufferMap = remainingBufferMap
                        , bufferIdMap = remainingBufferIdMap
                        , currentBufferId = newCurrentBufferId
                      }
                    , Task.perform identity <| Task.succeed <| ChangeBuffer newCurrentBufferId
                    )

            Noop ->
                ( model, Cmd.none )


updateCurrentBuffer : Model -> Buffer -> Model
updateCurrentBuffer model newBuffer =
    { model | bufferMap = D.insert model.currentBufferId newBuffer model.bufferMap }



-- View


view : Model -> Html Msg
view model =
    div [ id "openirc" ]
        [ buffersDiv model
        , currentBufferDiv model
        ]


buffersDiv : Model -> Html Msg
buffersDiv model =
    div [ id "buffers" ]
        [ ul [ id "buffer-list" ]
            ([ serverNameItem "서버 A" ] ++ bufferNameItems model ++ [ newBufferItem model ])
        ]


serverNameItem : String -> Html Msg
serverNameItem name =
    li [ class "buffer-item server-name" ] [ text name ]


bufferNameItems : Model -> List (Html Msg)
bufferNameItems model =
    let
        itemClass serverName channelName =
            case D.get ( serverName, channelName ) model.bufferIdMap of
                Just id ->
                    if id == model.currentBufferId then
                        "buffer-item buffer-name buffer-selected"
                    else
                        "buffer-item buffer-name"

                Nothing ->
                    "buffer-item buffer-name"

        getBufferId serverName channelName =
            case D.get ( serverName, channelName ) model.bufferIdMap of
                Just id ->
                    id

                Nothing ->
                    -1

        closeAnchor bufferId =
            a [ class "buffer-close", onClick <| CloseBuffer bufferId ] [ text "✘" ]

        render =
            (\( serverName, channelName ) ->
                li
                    [ class (itemClass serverName channelName)
                    , onClick <| ChangeBuffer (getBufferId serverName channelName)
                    ]
                    [ text channelName, closeAnchor (getBufferId serverName channelName) ]
            )
    in
        List.map render (D.keys model.bufferIdMap)


newBufferItem : Model -> Html Msg
newBufferItem model =
    li [ class "buffer-item new-buffer" ]
        [ form [ id "new-buffer-form", onSubmit CreateBuffer ]
            [ input
                [ id "new-buffer-text"
                , placeholder "채널 이름"
                , autocomplete False
                , value model.newChannelName
                , onInput TypeNewName
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
        currentBuffer =
            getCurrentBuffer model
    in
        ul [ id "logs" ]
            (currentBuffer.lines
                |> List.map (\line -> li [] [ text ("<@" ++ line.nick ++ "> " ++ line.text) ])
            )


newLineForm : Model -> Html Msg
newLineForm model =
    let
        currentBuffer =
            getCurrentBuffer model

        currentNick =
            getCurrentNick model
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
