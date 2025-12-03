<?php

function contactsGet($data, $type)
{
    if ($type == 'customer') {
    $curl = curl_init();
    curl_setopt_array($curl, array(
      CURLOPT_URL => 'https://app.mydialoginsight.com/webservices/ofc4/contacts.ashx?method=Get',
      CURLOPT_RETURNTRANSFER => true,
      CURLOPT_ENCODING => '',
      CURLOPT_MAXREDIRS => 10,
      CURLOPT_TIMEOUT => 0,
      CURLOPT_FOLLOWLOCATION => true,
      CURLOPT_HTTP_VERSION => CURL_HTTP_VERSION_1_1,
      CURLOPT_CUSTOMREQUEST => 'POST',
      CURLOPT_POSTFIELDS =>'{
        "AuthKey": {
            "idKey": '.get_field('idkey_api_dialog_insight', 'option').',
            "Key": "'.get_field('key_api_dialog_insight', 'option').'"
        },
        "idProject": 17265784,
        "Clause": {
            "$type": "FieldClause",
            "Field": {
                "Name": "f_EMail"
            },
            "TypeOperator": "Equal",
            "ComparisonValue": "'.$data['customer']['email'].'"
        },
        "Tag": null
      }',
      CURLOPT_HTTPHEADER => array(
        'Content-Type: application/json'
      ),
    ));
    $response = curl_exec($curl);
    curl_close($curl);
    $response = json_decode($response, true);
}if ($type == 'seller') {
    $curl = curl_init();
    curl_setopt_array($curl, array(
      CURLOPT_URL => 'https://app.mydialoginsight.com/webservices/ofc4/contacts.ashx?method=Get',
      CURLOPT_RETURNTRANSFER => true,
      CURLOPT_ENCODING => '',
      CURLOPT_MAXREDIRS => 10,
      CURLOPT_TIMEOUT => 0,
      CURLOPT_FOLLOWLOCATION => true,
      CURLOPT_HTTP_VERSION => CURL_HTTP_VERSION_1_1,
      CURLOPT_CUSTOMREQUEST => 'POST',
      CURLOPT_POSTFIELDS =>'{
        "AuthKey": {
            "idKey": '.get_field('idkey_api_dialog_insight', 'option').',
            "Key": "'.get_field('key_api_dialog_insight', 'option').'"
        },
        "idProject": 17265784,
        "Clause": {
            "$type": "FieldClause",
            "Field": {
                "Name": "f_EMail"
            },
            "TypeOperator": "Equal",
            "ComparisonValue": "'.$data['seller']['email'].'"
        },
        "Tag": null
      }',
      CURLOPT_HTTPHEADER => array(
        'Content-Type: application/json'
      ),
    ));
    $response = curl_exec($curl);
    curl_close($curl);
    $response = json_decode($response, true);

}

    return $response;
}

function contactsMerge($data)
{
    $curl = curl_init();
    curl_setopt_array($curl, array(
      CURLOPT_URL => 'https://app.mydialoginsight.com/webservices/ofc4/contacts.ashx?method=Merge',
      CURLOPT_RETURNTRANSFER => true,
      CURLOPT_ENCODING => '',
      CURLOPT_MAXREDIRS => 10,
      CURLOPT_TIMEOUT => 0,
      CURLOPT_FOLLOWLOCATION => true,
      CURLOPT_HTTP_VERSION => CURL_HTTP_VERSION_1_1,
      CURLOPT_CUSTOMREQUEST => 'POST',
      CURLOPT_POSTFIELDS =>'{
        "AuthKey": {
            "idKey": '.get_field('idkey_api_dialog_insight', 'option').',
            "Key": "'.get_field('key_api_dialog_insight', 'option').'"
        },
        "idProject": 17265784,
        "Records": [
            {
                "ID": {
                    "key_f_EMail": "'.$data['customer']['email'].'"
                },
                "Data": {
                    "f_EMail": "'.$data['customer']['email'].'",
                    "f_FirstName": "'.$data['customer']['firstName'].'",
                    "f_LastName": "'.$data['customer']['lastName'].'"
                }
            }
        ],
        "MergeOptions": {
            "AllowInsert": true,
            "AllowUpdate": false,
            "SkipDuplicateRecords": false,
            "SkipUnmatchedRecords": false,
            "ReturnRecordsOnSuccess": false,
            "ReturnRecordsOnError": false,
            "FieldOptions": null
        }
      }',
      CURLOPT_HTTPHEADER => array(
        'Content-Type: application/json'
      ),
    ));
    $response = curl_exec($curl);
    curl_close($curl);
    $response = json_decode($response, true);

    return $response;
}

function merge($data)
{
    $contactsMergeResp = contactsMerge($data);
    if (!$contactsMergeResp['Success']) {
        logger("ErrorCode: " . print_r($contactsMergeResp['ErrorCode'], true));
        logger("ErrorMessage: " . print_r($contactsMergeResp['ErrorMessage'], true));
    } else {
        if (!empty($contactsMergeResp['Records']) && isset($contactsMergeResp['Records'][0]['IdRecord'])) {
            $idContact = $contactsMergeResp['Records'][0]['IdRecord'];
            logger("Record inserted with IdRecord: " . $idContact);
        } else {
            logger("Error: 'IdRecord' is missing from the merge response.");
        }
    }
}
