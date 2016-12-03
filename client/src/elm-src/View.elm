module View exposing (..)

import Html exposing (..)
import Html.Events exposing (onSubmit, onInput, onClick)
import Html.Attributes exposing (id, class, type_, placeholder, value, autocomplete)
import Dict as D
import Tuple exposing (second)
import Model exposing (..)
import Update exposing (Msg(..))


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
