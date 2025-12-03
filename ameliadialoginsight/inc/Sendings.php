<?php

function sendingsSendSingle2($data, $type)
{
    $products = !empty($data['products']) ? ',' . $data['products'] : '';
    $ov_products = !empty($data['ov_products']) ? ',' . $data['ov_products'] : '';
    $curl = curl_init();
    if ($type == 'customer') {
        curl_setopt_array($curl, array(
          CURLOPT_URL => 'https://app.mydialoginsight.com/webservices/ofc4/sendings.ashx?method=SendSingle2',
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
            "idMessage": 356,
            "ContactFilter": {
                "Mode": "Single",
                "idContact": '.$data['idContact'].'
            },
            "SendSingleOptions": {
                "idMessageVersion": null,
                "MessageParameterValues": {
                    "motif_du_rendez_vous": "'.$data['motif_demande'].'",
                    "boutique_nom": "'.$data['shopName'].'",
                    "boutique_lien": "'.$data['boutique_lien'].'",
                    "boutique_tel": "'.$data['boutique_tel'].'",
                    "boutique_adresse": "'.$data['boutique_adresse'].'",
                    "boutique_map_img": "'.$data['boutique_map_img'].'",
                    "boutique_map_link": "'.$data['boutique_map_link'].'",
                    "event_start_time": "'.$data['date'].'",
                    "event_start_hour": "'.$data['heure'].'",
                    "examination": "'.$data['dernier_examen'].'",
                    "examination_ask": "'.$data['examen_a_faire'].'",
                    "examination_ask_audition": "'.$data['depistage'].'",
                    "new_customer": "'.$data['nouveau_client'].'",
                    "discount": "",
                    "discount_title": "",
                    "discount_description": "",
                    "discount_code": "",
                    "assistant": "Opticien Optic Duroc",
                    "assistant_avatar": "https://opticduroc.com/wp-content/uploads/2018/09/HOMME.jpg",
                    "ov_answer1": "'.$data['type_de_monture'].'",
                    "ov_answer2": "'.$data['genre'].'",
                    "ov_answer3": "'.$data['geometrie_face_type'].'",
                    "ov_answer4": "'.$data['style_de_monture'].'",
                    "ov_answer5": "'.$data['coloris'].'",
                    "ov_answer6": "'.$data['matiere_de_la_monture'].'"
                    '.$products.'
                    '.$ov_products.'
                },
                "DiscardParametersAfterSending": false
            },
            "Attachments": null
          }',
          CURLOPT_HTTPHEADER => array(
            'Content-Type: application/json'
          ),
        ));
        logger('CURLOPT_POSTFIELDS customer: {
            "AuthKey": {
                "idKey": '.get_field('idkey_api_dialog_insight', 'option').',
                "Key": "'.get_field('key_api_dialog_insight', 'option').'"
            },
            "idProject": 17265784,
            "idMessage": 356,
            "ContactFilter": {
                "Mode": "Single",
                "idContact": '.$data['idContact'].'
            },
            "SendSingleOptions": {
                "idMessageVersion": null,
                "MessageParameterValues": {
                    "motif_du_rendez_vous": "'.$data['motif_demande'].'",
                    "boutique_nom": "'.$data['shopName'].'",
                    "boutique_lien": "'.$data['boutique_lien'].'",
                    "boutique_tel": "'.$data['boutique_tel'].'",
                    "boutique_adresse": "'.$data['boutique_adresse'].'",
                    "boutique_map_img": "'.$data['boutique_map_img'].'",
                    "boutique_map_link": "'.$data['boutique_map_link'].'",
                    "event_start_time": "'.$data['date'].'",
                    "event_start_hour": "'.$data['heure'].'",
                    "examination": "'.$data['dernier_examen'].'",
                    "examination_ask": "'.$data['examen_a_faire'].'",
                    "examination_ask_audition": "'.$data['depistage'].'",
                    "new_customer": "'.$data['nouveau_client'].'",
                    "discount": "",
                    "discount_title": "",
                    "discount_description": "",
                    "discount_code": "",
                    "assistant": "Opticien Optic Duroc",
                    "assistant_avatar": "https://opticduroc.com/wp-content/uploads/2018/09/HOMME.jpg",
                    "ov_answer1": "'.$data['type_de_monture'].'",
                    "ov_answer2": "'.$data['genre'].'",
                    "ov_answer3": "'.$data['geometrie_face_type'].'",
                    "ov_answer4": "'.$data['style_de_monture'].'",
                    "ov_answer5": "'.$data['coloris'].'",
                    "ov_answer6": "'.$data['matiere_de_la_monture'].'"
                    '.$products.'
                    '.$ov_products.'
                },
                "DiscardParametersAfterSending": false
            },
            "Attachments": null
          }');
    } else {
        curl_setopt_array($curl, array(
          CURLOPT_URL => 'https://app.mydialoginsight.com/webservices/ofc4/sendings.ashx?method=SendSingle2',
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
            "idMessage": 357,
            "ContactFilter": {
                "Mode": "Single",
                "idContact": '.$data['idContactMag'].'
            },
            "SendSingleOptions": {
                "idMessageVersion": null,
                "MessageParameterValues": {
                    "motif_du_rendez_vous": "'.$data['motif_demande'].'",
                    "client_nom": "'.$data['customer']['firstName'].' '.$data['customer']['lastName'].'",
                    "client_mail": "'.$data['customer']['email'].'",
                    "client_tel": "'.substr($data['customer']['phone'], 3).'",
                    "boutique_nom": "'.$data['shopName'].'",
                    "boutique_lien": "'.$data['boutique_lien'].'",
                    "boutique_tel": "'.$data['boutique_tel'].'",
                    "boutique_adresse": "'.$data['boutique_adresse'].'",
                    "boutique_map_img": "'.$data['boutique_map_img'].'",
                    "boutique_map_link": "'.$data['boutique_map_link'].'",
                    "event_start_time": "'.$data['date'].'",
                    "event_start_hour": "'.$data['heure'].'",
                    "examination": "'.$data['dernier_examen'].'",
                    "examination_ask": "'.$data['examen_a_faire'].'",
                    "examination_ask_audition": "'.$data['depistage'].'",
                    "new_customer": "'.$data['nouveau_client'].'",
                    "discount": "",
                    "discount_title": "",
                    "discount_description": "",
                    "discount_code": "",
                    "assistant": "Opticien Optic Duroc",
                    "assistant_avatar": "https://opticduroc.com/wp-content/uploads/2018/09/HOMME.jpg",
                    "ov_answer1": "'.$data['type_de_monture'].'",
                    "ov_answer2": "'.$data['genre'].'",
                    "ov_answer3": "'.$data['geometrie_face_type'].'",
                    "ov_answer4": "'.$data['style_de_monture'].'",
                    "ov_answer5": "'.$data['coloris'].'",
                    "ov_answer6": "'.$data['matiere_de_la_monture'].'"
                    '.$products.'
                    '.$ov_products.'
                },
                "DiscardParametersAfterSending": false
            },
            "Attachments": null
          }',
          CURLOPT_HTTPHEADER => array(
            'Content-Type: application/json'
          ),
        ));
        logger('CURLOPT_POSTFIELDS seller: {
            "AuthKey": {
                "idKey": '.get_field('idkey_api_dialog_insight', 'option').',
                "Key": "'.get_field('key_api_dialog_insight', 'option').'"
            },
            "idProject": 17265784,
            "idMessage": 357,
            "ContactFilter": {
                "Mode": "Single",
                "idContact": '.$data['idContactMag'].'
            },
            "SendSingleOptions": {
                "idMessageVersion": null,
                "MessageParameterValues": {
                    "motif_du_rendez_vous": "'.$data['motif_demande'].'",
                    "client_nom": "'.$data['customer']['firstName'].' '.$data['customer']['lastName'].'",
                    "client_mail": "'.$data['customer']['email'].'",
                    "client_tel": "'.substr($data['customer']['phone'], 3).'",
                    "boutique_nom": "'.$data['shopName'].'",
                    "boutique_lien": "'.$data['boutique_lien'].'",
                    "boutique_tel": "'.$data['boutique_tel'].'",
                    "boutique_adresse": "'.$data['boutique_adresse'].'",
                    "boutique_map_img": "'.$data['boutique_map_img'].'",
                    "boutique_map_link": "'.$data['boutique_map_link'].'",
                    "event_start_time": "'.$data['date'].'",
                    "event_start_hour": "'.$data['heure'].'",
                    "examination": "'.$data['dernier_examen'].'",
                    "examination_ask": "'.$data['examen_a_faire'].'",
                    "examination_ask_audition": "'.$data['depistage'].'",
                    "new_customer": "'.$data['nouveau_client'].'",
                    "discount": "",
                    "discount_title": "",
                    "discount_description": "",
                    "discount_code": "",
                    "assistant": "Opticien Optic Duroc",
                    "assistant_avatar": "https://opticduroc.com/wp-content/uploads/2018/09/HOMME.jpg",
                    "ov_answer1": "'.$data['type_de_monture'].'",
                    "ov_answer2": "'.$data['genre'].'",
                    "ov_answer3": "'.$data['geometrie_face_type'].'",
                    "ov_answer4": "'.$data['style_de_monture'].'",
                    "ov_answer5": "'.$data['coloris'].'",
                    "ov_answer6": "'.$data['matiere_de_la_monture'].'"
                    '.$products.'
                    '.$ov_products.'
                },
                "DiscardParametersAfterSending": false
            },
            "Attachments": null
          }');
    }
    $response = curl_exec($curl);
    curl_close($curl);
    $response = json_decode($response, true);

    return $response;
}
