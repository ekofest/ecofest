module Helpers exposing (..)

import Dict exposing (Dict)
import File exposing (File)
import FormatNumber exposing (format)
import FormatNumber.Locales exposing (Decimals(..), frenchLocale)
import Json.Decode as Decode exposing (Decoder)
import Publicodes as P
import Regex


resultNamespace : P.RuleName
resultNamespace =
    "resultats"


totalRuleName : P.RuleName
totalRuleName =
    "resultats . bilan total"


{-| TODO: should be defined in ui.yaml?
-}
getResultRules : P.RawRules -> List ( P.RuleName, P.RawRule )
getResultRules rules =
    rules
        |> Dict.toList
        |> List.filterMap
            (\( name, rule ) ->
                case P.splitRuleName name of
                    [ namespace, _ ] ->
                        if namespace == resultNamespace then
                            Just ( name, rule )

                        else
                            Nothing

                    _ ->
                        Nothing
            )


getQuestions : P.RawRules -> List String -> Dict String (List P.RuleName)
getQuestions rules categories =
    Dict.toList rules
        |> List.filterMap
            (\( name, rule ) ->
                Maybe.map (\_ -> name) rule.question
            )
        |> List.foldl
            (\name dict ->
                let
                    category =
                        P.namespace name
                in
                if List.member category categories then
                    Dict.update category
                        (\maybeList ->
                            case maybeList of
                                Just list ->
                                    Just (name :: list)

                                Nothing ->
                                    Just [ name ]
                        )
                        dict

                else
                    dict
            )
            Dict.empty


isInCategory : P.RuleName -> P.RuleName -> Bool
isInCategory category ruleName =
    P.splitRuleName ruleName
        |> List.head
        |> Maybe.withDefault ""
        |> (\namespace -> namespace == category)


getTitle : P.RawRules -> P.RuleName -> String
getTitle rules name =
    case Dict.get name rules of
        Just rule ->
            Maybe.withDefault name rule.title

        Nothing ->
            name


getStringFromSituation : P.NodeValue -> String
getStringFromSituation stringValue =
    let
        regex =
            Maybe.withDefault Regex.never (Regex.fromString "^'|'$")
    in
    stringValue
        |> P.nodeValueToString
        |> Regex.replace regex (\_ -> "")


{-| TODO: should find a way to use the [disambiguateReference] function from
[publicodes]
-}
getOptionTitle : P.RawRules -> P.RuleName -> P.RuleName -> String
getOptionTitle rules contexte optionVal =
    rules
        |> Dict.get (contexte ++ " . " ++ optionVal)
        |> Maybe.andThen (\r -> r.title)
        |> Maybe.withDefault optionVal


formatFloatToFrenchLocale : Int -> Float -> String
formatFloatToFrenchLocale n =
    format { frenchLocale | decimals = Exact n }


formatPercent : Float -> String
formatPercent pct =
    formatFloatToFrenchLocale 1 pct ++ " %"


filesDecoder : Decoder (List File)
filesDecoder =
    Decode.at [ "target", "files" ] (Decode.list File.decoder)


{-| Drops elements from [list] until the next element satisfies [predicate].

@returns [] if no element satisfies the [predicate].
@returns [list] if the first element satisfies the [predicate].

    dropUntilNext ((==) 3) [ 1, 2, 3, 4, 5 ] == [ 2, 3, 4, 5 ]

    dropUntilNext ((==) 3) [ 1, 2, 3 ] == [ 2, 3 ]

    dropUntilNext ((==) 3) [ 1, 2 ] == []

    dropUntilNext ((==) 3) [ 3, 4, 5 ] == [ 3, 4, 5 ]

-}
dropUntilNext : (a -> Bool) -> List a -> List a
dropUntilNext predicate list =
    let
        go l =
            case l of
                _ :: x :: xs ->
                    if predicate x then
                        l

                    else
                        go (x :: xs)

                _ ->
                    []
    in
    case list of
        x :: _ ->
            if predicate x then
                list

            else
                go list

        _ ->
            []
