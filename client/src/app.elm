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


type alias Model =
    { bufferMap : Dict ( String, String ) Buffer
    , nickMap : Dict String String
    , currentServerName : String
    , currentChannelName : String
    , newChannelName : String
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
            [ ( "InitServer", "InitNick" ) ]
        )
        "InitServer"
        "#a"
        ""


getBuffer : Model -> ( String, String ) -> Buffer
getBuffer model namePair =
    case D.get namePair model.bufferMap of
        Nothing ->
            Buffer [ Line "NOTICE" "Currently not in a (valid) buffer." ] ""

        Just buffer ->
            buffer


getNick : Model -> String -> String
getNick model serverName =
    case D.get serverName model.nickMap of
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
    | ChangeBuffer ( String, String )
    | CloseBuffer ( String, String )
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
                    currentServerName =
                        model.currentServerName

                    newChannelName =
                        model.newChannelName

                    newBufferMap =
                        D.insert ( currentServerName, newChannelName ) (Buffer [] "") model.bufferMap
                in
                    if
                        (D.member ( currentServerName, newChannelName ) model.bufferMap
                            || isEmpty newChannelName
                            || not (startsWith "#" newChannelName)
                        )
                    then
                        {- Error notification logic should be added -}
                        ( model, Cmd.none )
                    else
                        ( { model
                            | bufferMap = newBufferMap
                            , newChannelName = ""
                          }
                        , Task.perform identity (Task.succeed <| ChangeBuffer ( currentServerName, newChannelName ))
                        )

            ChangeBuffer ( newServerName, newChannelName ) ->
                ( { model | currentServerName = newServerName, currentChannelName = newChannelName }
                , Task.attempt (\_ -> Noop) (toBottom "logs")
                )

            CloseBuffer closingNamePair ->
                let
                    remainingBufferMap =
                        model.bufferMap
                            |> D.filter (\namePair _ -> namePair /= closingNamePair)

                    newNamePair =
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
                        , currentServerName = first newNamePair
                        , currentChannelName = second newNamePair
                      }
                    , Task.perform identity <| Task.succeed <| ChangeBuffer newNamePair
                    )

            Noop ->
                ( model, Cmd.none )


updateCurrentBuffer : Model -> Buffer -> Model
updateCurrentBuffer model newBuffer =
    { model | bufferMap = D.insert ( model.currentServerName, model.currentChannelName ) newBuffer model.bufferMap }



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


serverNameItem : String -> Html Msg
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
