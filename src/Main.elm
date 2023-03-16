module Main exposing (main)

import Browser
import Dict exposing (Dict)
import Element exposing (..)
import Element.Border as Border
import Element.Font as Font
import Element.Input as Input
import Html exposing (Html)
import Http
import Json.Decode as D exposing (Decoder)



-- DATA INCOMING --


type alias DataFamily =
    { name : String
    , units : List DataUnit
    }


type alias DataUnit =
    { name : String
    , combinations : List DataCombination
    }


type alias DataCombination =
    { base : List String
    , secondary : List String
    , notes : String
    }



-- DOMAIN DATA --


type alias Unit =
    { name : String
    , family : String
    , combinesFrom : List MultiCombination
    , combinesInto : List MultiCombination
    }


type alias Family =
    { name : String
    , units : List String
    }


type alias MultiCombination =
    { base : List String
    , secondary : List String
    , result : String
    , notes : String
    }



-- MODEL --


type alias Tab =
    { name : String
    , fileHref : String
    }


type SelectionData
    = NoSelection
    | UnitSelection Unit
    | FamilySelection Family


type alias Model =
    { selection : SelectionData
    , tabs : List Tab
    , selectedTab : Tab
    , data :
        { unitsByName : Dict String Unit
        , familiesByName : Dict String Family
        }
    , lastError : String
    , baseUrl : String
    }


init : flags -> ( Model, Cmd Msg )
init _ =
    let
        defaultTab =
            { name = "Dragon Warrior Monsters 1"
            , fileHref = "/data/dwm1/data.json"
            }
    in
    ( { selection =
            NoSelection
      , tabs =
            [ defaultTab
            ]
      , selectedTab = defaultTab
      , data =
            { unitsByName =
                Dict.empty
            , familiesByName =
                Dict.empty
            }
      , lastError = ""
      , baseUrl = "/combinator"
      }
    , Cmd.none
    )



-- MESSAGE --


type Msg
    = NoOp
    | ClickName String
    | ClickTab Tab
    | ReceiveData (Result Http.Error (List DataFamily))


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        NoOp ->
            ( model, Cmd.none )

        ClickName name ->
            if String.toUpper name == name then
                case Dict.get name model.data.familiesByName of
                    Nothing ->
                        ( model, Cmd.none )

                    Just family ->
                        ( { model | selection = FamilySelection family }, Cmd.none )

            else
                case Dict.get name model.data.unitsByName of
                    Nothing ->
                        ( model, Cmd.none )

                    Just unit ->
                        ( { model | selection = UnitSelection unit }, Cmd.none )

        ClickTab tab ->
            ( { model
                | selectedTab = tab
              }
            , fetchData model.baseUrl tab.fileHref
            )

        ReceiveData result ->
            case result of
                Ok data ->
                    ( { model
                        | data =
                            { unitsByName = unitDataConverter data
                            , familiesByName = familyDataConverter data
                            }
                      }
                    , Cmd.none
                    )

                Err err ->
                    case err of
                        Http.BadUrl url ->
                            ( { model | lastError = "bad url: " ++ url }, Cmd.none )

                        Http.BadStatus status ->
                            ( { model | lastError = "bad status: " ++ String.fromInt status }, Cmd.none )

                        Http.Timeout ->
                            ( { model | lastError = "network request timed out" }, Cmd.none )

                        Http.NetworkError ->
                            ( { model | lastError = "network error occurred" }, Cmd.none )

                        Http.BadBody body ->
                            ( { model | lastError = "bad body: " ++ body }, Cmd.none )



-- VIEW --


view : Model -> Html Msg
view model =
    layout [] <|
        column
            [ spacing 40 ]
            [ viewTabs model.tabs
            , viewFamilies <| Dict.keys model.data.familiesByName
            , viewSelection model.selection
            ]


viewTabs : List Tab -> Element Msg
viewTabs tabs =
    row
        [ padding 10
        , spacing 4
        ]
    <|
        List.map viewClickableTab tabs


viewSelection : SelectionData -> Element Msg
viewSelection selection =
    case selection of
        NoSelection ->
            none

        UnitSelection s ->
            let
                headerStyle =
                    [ Font.size 24
                    , paddingXY 0 20
                    ]

                tableStyle =
                    [ Border.solid
                    , padding 20
                    , alignTop
                    , Border.widthEach
                        { bottom = 1
                        , top = 1
                        , left = 0
                        , right = 0
                        }
                    ]
            in
            column
                -- Title and content
                [ padding 20
                , spacing 40
                ]
                [ el
                    [ paddingXY 250 0
                    , Font.size 40
                    ]
                  <|
                    text s.name
                , row
                    -- Combines from | to
                    [ spacing 200
                    ]
                    [ column tableStyle <|
                        (el headerStyle <| text "Combines From:")
                            :: List.map (viewMultiCombination False) s.combinesFrom
                    , column tableStyle <|
                        (el headerStyle <| text "Combines Into:")
                            :: List.map (viewMultiCombination True) s.combinesInto
                    ]
                ]

        FamilySelection f ->
            column
                -- Title and content
                [ padding 20
                , spacing 20
                ]
                [ el
                    [ paddingXY 250 0
                    , Font.size 40
                    ]
                  <|
                    text <|
                        f.name
                            ++ " FAMILY"
                , wrappedRow
                    [ spacingXY 20 10
                    , width <| px 800
                    ]
                    (List.map (\unitName -> viewClickableName unitName) f.units)
                ]


viewMultiCombination : Bool -> MultiCombination -> Element Msg
viewMultiCombination includeResult combination =
    let
        parentColumnStyle =
            [ width <| px 120
            , spacing 4
            ]
        operatorStyle =
            [ centerX
            , width <| px 40
            , Font.size 25
            ]
    in
    row
        [ spacing 10
        , padding 10
        , Border.dashed
        , Border.widthEach
            { bottom = 0
            , top = 1
            , left = 0
            , right = 0
            }
        ]
    <|
        (if includeResult then
            [ el parentColumnStyle <| viewClickableName combination.result
            , el operatorStyle <| text "="
            ]

         else
            [ none ]
        )
            ++ [ column parentColumnStyle <| List.map (\parent -> viewClickableName parent) combination.base
               , el operatorStyle <| text "+"
               , column parentColumnStyle <| List.map (\parent -> viewClickableName parent) combination.secondary
               , el parentColumnStyle <| text combination.notes
               ]


viewFamilies : List String -> Element Msg
viewFamilies families =
    column
        [ padding 20
        , spacing 30
        ]
        [ el [ Font.size 24 ] <| text "Families:"
        , row
            [ Font.size 20
            , spacing 20
            ]
            (List.map (\f -> viewClickableName f) families)
        ]


viewClickableName : String -> Element Msg
viewClickableName name =
    Input.button
        [ Font.color <| rgb 0 0.3 1
        , Font.family [ Font.monospace ]
        ]
        { onPress = Just <| ClickName name
        , label = text name
        }


viewClickableTab : Tab -> Element Msg
viewClickableTab tab =
    Input.button
        [ Font.color <| rgb 0 0.3 1
        , Font.family [ Font.monospace ]
        , padding 20
        , Font.size 24
        , Border.solid
        , Border.width 1
        , Border.color <| rgb 0 0 0
        ]
        { onPress = Just <| ClickTab tab
        , label = text tab.name
        }



-- SUBSCRIPTIONS --


subscriptions : Model -> Sub Msg
subscriptions _ =
    Sub.none



-- JSON DECODE --


dataDecoder : Decoder (List DataFamily)
dataDecoder =
    D.list <|
        D.map2 DataFamily
            (D.field "name" D.string)
            (D.field "units" <|
                D.list <|
                    D.map2 DataUnit
                        (D.field "name" D.string)
                        (D.field "combinations" <|
                            D.list <|
                                D.map3 DataCombination
                                    (D.field "base" <| D.list D.string)
                                    (D.field "secondary" <| D.list D.string)
                                    (D.field "notes" D.string)
                        )
            )


familyDataConverter : List DataFamily -> Dict String Family
familyDataConverter dataFamilies =
    Dict.fromList <|
        List.map
            (\family ->
                ( family.name
                , { name = family.name
                  , units =
                        List.map
                            (\unit -> unit.name)
                            family.units
                  }
                )
            )
            dataFamilies


unitDataConverter : List DataFamily -> Dict String Unit
unitDataConverter dataFamilies =
    Dict.fromList <|
        List.concatMap
            (\family ->
                List.map
                    (\unit ->
                        ( unit.name
                        , { name = unit.name
                          , family = family.name
                          , combinesFrom =
                                List.map
                                    (\c ->
                                        { base = c.base
                                        , secondary = c.secondary
                                        , notes = c.notes
                                        , result = unit.name
                                        }
                                    )
                                    unit.combinations
                          , combinesInto = getCombinesInto dataFamilies unit
                          }
                        )
                    )
                    family.units
            )
            dataFamilies


getCombinesInto : List DataFamily -> DataUnit -> List MultiCombination
getCombinesInto dataFamilies unit =
    List.concatMap
        (\family2 ->
            List.concatMap
                (\unit2 ->
                    List.filterMap
                        (\c ->
                            if List.member unit.name c.base || List.member unit.name c.secondary then
                                Just
                                    { base = c.base
                                    , secondary = c.secondary
                                    , notes = c.notes
                                    , result = unit2.name
                                    }

                            else
                                Nothing
                        )
                        unit2.combinations
                )
                family2.units
        )
        dataFamilies



-- COMMANDS --


fetchData : String -> String -> Cmd Msg
fetchData baseUrl fileHref =
    Http.get
        { url = baseUrl ++ fileHref
        , expect = Http.expectJson ReceiveData dataDecoder
        }



-- MAIN --


main : Program () Model Msg
main =
    Browser.element
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        }
