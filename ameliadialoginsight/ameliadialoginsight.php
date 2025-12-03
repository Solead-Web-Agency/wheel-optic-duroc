<?php
/*
Plugin Name: (AM) Amelia to Dialog Insight
Description: Sync between Amelia & Dialog Insight.
Version: 1.0.0
Author: Latoutfrancais
*/

// ini_set('display_errors', 1);
// ini_set('display_startup_errors', 1);
// error_reporting(E_ALL);

// Required files
if ( file_exists( plugin_dir_path( __FILE__ ) . 'inc/Log.php' ) ) {
    require( plugin_dir_path( __FILE__ ) . 'inc/Log.php' );
} else {
    die('required file Log.php not found');
}
if ( file_exists( plugin_dir_path( __FILE__ ) . 'inc/Contacts.php' ) ) {
    require( plugin_dir_path( __FILE__ ) . 'inc/Contacts.php' );
} else {
    die('required file Contacts.php not found');
}
if ( file_exists( plugin_dir_path( __FILE__ ) . 'inc/Sendings.php' ) ) {
    require( plugin_dir_path( __FILE__ ) . 'inc/Sendings.php' );
} else {
    die('required file Sendings.php not found');
}

// Define the sync function
function syncDialogInsight($reservation, $bookings, $container) {
    global $wpdb;
    $siteUrl = site_url('', 'https');
    logger("New sync");

    $data = [];
    $data['customer'] = $reservation['bookings'][0]['customer'];
    $data['seller'] = $reservation['provider'];
    $data['dernier_examen'] = ($reservation['bookings'][0]['customFields'][1]['value']) ? $reservation['bookings'][0]['customFields'][1]['value'] : 'nc';
    $data['nouveau_client'] = ($reservation['bookings'][0]['customFields'][2]['value']) ? 1 : 0;
    $data['examen_a_faire'] = ($reservation['bookings'][0]['customFields'][3]['value']) ? 1 : 0;
    $data['lunettes_string'] = (isset($_SESSION['choices']['offers']) && $_SESSION['choices']['offers']) ? 'Lunettes: ' . implode(', ', $_SESSION['choices']['offers']) : '';
    $data['lunettes'] = (isset($_SESSION['choices']['offers']) && $_SESSION['choices']['offers']) ? $_SESSION['choices']['offers'] : '';
    $data['type_de_monture'] = (isset($_SESSION['choices']['type_de_monture']) && $_SESSION['choices']['type_de_monture']) ? 'Type de monture: ' . implode(', ', $_SESSION['choices']['type_de_monture']) : '';
    $data['genre'] = (isset($_SESSION['choices']['genre']) && $_SESSION['choices']['genre']) ? 'Genre: ' . implode(', ', $_SESSION['choices']['genre']) : '';
    $data['geometrie_face_type'] = (isset($_SESSION['choices']['geometrie_face_type']) && $_SESSION['choices']['geometrie_face_type']) ? 'Forme du visage: ' . implode(', ', $_SESSION['choices']['geometrie_face_type']) : '';
    $data['style_de_monture'] = (isset($_SESSION['choices']['style_de_monture']) && $_SESSION['choices']['style_de_monture']) ? 'Style de monture: ' . implode(', ', $_SESSION['choices']['style_de_monture']) : '';
    $data['coloris'] = (isset($_SESSION['choices']['coloris']) && $_SESSION['choices']['coloris']) ? 'Coloris: ' . implode(', ', $_SESSION['choices']['coloris']) : '';
    $data['matiere_de_la_monture'] = (isset($_SESSION['choices']['matiere_de_la_monture']) && $_SESSION['choices']['matiere_de_la_monture']) ? 'Matière de la monture: ' . implode(', ', $_SESSION['choices']['matiere_de_la_monture']) : '';
    $data['depistage'] = ($_SESSION['depistage'] == "oui") ? 'oui' : 'non';
    $data['date'] = substr($reservation['bookingStart'], 0, 10);
    $data['heure'] = substr($reservation['bookingStart'], 11);
    // $data['shopName'] = (isset($_SESSION['shopName']) && $_SESSION['shopName']) ? $_SESSION['shopName'] : 'nc';
    $data['shopName'] = (isset($_SESSION['shopName']) && $_SESSION['shopName']) ? $_SESSION['shopName'] : $reservation['location']['name'];

    if (isset($_SESSION['motif_demande']) && $_SESSION['motif_demande']) {
        $data['motif_demande'] = $_SESSION['motif_demande'];
    } else {
        $data['motif_demande'] = $reservation['service']['name'];
    }
    $data['commentaire_demande'] = (isset($_SESSION['commentaire_demande']) && $_SESSION['commentaire_demande']) ? $_SESSION['commentaire_demande'] : '';
    $data['commentaire'] = 'Date créneau: ' . $date . ' ' . $heure . "\nE-mail: " . $customer['email'];
    $elements = [
        $type_de_monture,
        $genre,
        $geometrie_face_type,
        $style_de_monture,
        $coloris,
        $matiere_de_la_monture,
        $commentaire_demande,
        $lunettes,
        'Boutique: ' . $shopName,
        'Dépistage auditif: ' . $depistage,
        'Dernier examen: ' . $dernier_examen,
        'Nouveau client: ' . $nouveau_client,
        'Examen à faire: ' . $examen_a_faire
    ];
    foreach ($elements as $element) {
        if (!empty($element)) {
            $commentaire .= "\n" . $element;
        }
    }
    $locationName = sanitize_text_field($reservation['location']['name']);
    $query = $wpdb->prepare(
        "SELECT pm.meta_value FROM {$wpdb->prefix}posts p
        JOIN {$wpdb->prefix}postmeta pm ON p.ID = pm.post_id
        WHERE p.post_title = %s AND p.post_type = 'wpsl_stores' AND pm.meta_key = %s LIMIT 1",
        $locationName,
        'wpsl_url'
    );
    // $data['boutique_lien'] = $wpdb->get_var($query);
    $data['boutique_lien'] = $wpdb->get_var($query);

    // URL de base à vérifier
    $baseUrl = "https://opticduroc.com";

    // Vérifier et formater le lien
    if (strpos($data['boutique_lien'], $baseUrl) !== 0) {
        // Si le lien ne commence pas par l'URL de base, on l'ajoute
        $data['boutique_lien'] = rtrim($baseUrl, '/') . '/' . ltrim($data['boutique_lien'], '/');
    } else {
        // Si l'URL de base est déjà présente, on vérifie et ajuste le chemin
        $path = substr($data['boutique_lien'], strlen($baseUrl));
        $data['boutique_lien'] = rtrim($baseUrl, '/') . '/' . ltrim($path, '/');
    }

    $data['boutique_tel'] = $reservation['location']['phone'];
    $data['boutique_adresse'] = $reservation['location']['address'];
    $data['boutique_map_img'] = $reservation['location']['pictureFullPath'];
    $data['boutique_map_link'] = 'https://maps.google.com/?q='.$reservation['location']['address'];

    $data['products'] = null;
    if (WC()->cart && !WC()->cart->is_empty()) {

        $jsonCartProductsArray = [];
        $key = 0;
        foreach ( WC()->cart->get_cart() as $cart_item_key => $cart_item ) {
            if ($key >= 3) break;
            if ($cart_item['data'] instanceof WC_Product_Variation) {
                $variation = $cart_item['data'];
                $postParentId = $variation->get_parent_id();
            } else {
                $postParentId = $data['product_id'];
            }
            $product = wc_get_product($postParentId);
            $lunetteName = $product->get_name();
            $lunetteLink = get_permalink($postParentId);
            $lunetteImage = wp_get_attachment_url(get_post_thumbnail_id($postParentId));
            $style_de_monture_terms = wp_get_post_terms($postParentId, 'style-de-monture', array("fields" => "names"));
            $lunetteShape = !empty($style_de_monture_terms) ? implode(',', $style_de_monture_terms) : '';
            $coloris_terms = wp_get_post_terms($postParentId, 'coloris', array("fields" => "names"));
            $lunetteColor = !empty($coloris_terms) ? implode(',', $coloris_terms) : '';
            if ($product->is_type('variable')) {
                $variations = $product->get_available_variations();
                $lowest_price = null;
                foreach ($variations as $variation) {
                    $variation_obj = wc_get_product($variation['variation_id']);
                    $variation_price = $variation_obj->get_sale_price() ?: $variation_obj->get_regular_price();
                    //$variation_price = $variation_obj->get_regular_price();
                    if (is_null($lowest_price) || $variation_price < $lowest_price) {
                        $lowest_price = $variation_price;
                    }
                }
                $lunettePrice = $lowest_price;
            } else {
                $lunettePrice = $product->get_sale_price() ?: $product->get_regular_price();
                //$lunettePrice = $product->get_regular_price();
            }

                 // New code for color images
            $lunetteColorImage = null;
            $attributes = $product->get_attributes();
            $color_images = [];

            if (isset($attributes['pa_couleurs'])) {
                $attribute = $attributes['pa_couleurs'];

                if ($attribute instanceof WC_Product_Attribute) {
                    $options = $attribute->get_options();
                    $isw_settings = get_option('isw_settings');
                    $color_index = isset($isw_settings['isw_attr']) ? array_search('pa_couleurs', $isw_settings['isw_attr']) : null;
                    $custom_colors = $color_index !== false ? ($isw_settings['isw_custom'][$color_index] ?? []) : [];

                    $couleurs = array_map(function ($term_id) use (&$color_images, $custom_colors) {
                        $term = get_term_by('id', $term_id, 'pa_couleurs');
                        if ($term) {
                            $color_name = $term->name;
                            $color_image = $custom_colors[strtolower($color_name)] ?? null;
                            if ($color_image) {
                                $color_images[strtolower($color_name)] = $color_image;
                                return $color_image;
                            }
                        }
                        return null;
                    }, $options);
                    $lunetteColorImage = reset($color_images); // Get the first color image
                }
            }
            $index = $key + 1;
            $key++;
            $jsonCartProductsArray["product{$index}_name"] = $lunetteName;
            $jsonCartProductsArray["product{$index}_link"] = $lunetteLink;
            $jsonCartProductsArray["product{$index}_image"] = $lunetteImage;
            $jsonCartProductsArray["product{$index}_shape"] = $lunetteShape;
            $jsonCartProductsArray["product{$index}_color"] = $lunetteColorImage;
            $jsonCartProductsArray["product{$index}_price"] = $lunettePrice;
        }
        $jsonCartProducts = json_encode($jsonCartProductsArray, JSON_PRETTY_PRINT);
        $jsonCartProducts = trim($jsonCartProducts, '{}');
        $data['products'] = $jsonCartProducts;
    }

    $data['ov_products'] = null;
    if (!empty($data['lunettes'])) {
        $jsonProductsArray = [];
        foreach ($data['lunettes'] as $key => $lunette) {
            if ($key >= 3) break;
            $lunetteName = str_replace("–", "-", $lunette);
            $query = $wpdb->prepare(
                "SELECT ID FROM {$wpdb->prefix}posts
                WHERE post_title = %s AND post_type = 'product'",
                $lunetteName
            );
            $lunetteId = $wpdb->get_var($query);
            $lunetteLink = get_permalink($lunetteId);
            $lunetteImage = get_the_post_thumbnail_url($lunetteId, 'woocommerce_thumbnail');
            $style_de_monture_terms = wp_get_post_terms($lunetteId, 'style-de-monture', array("fields" => "names"));
            $lunetteShape = !empty($style_de_monture_terms) ? implode(',', $style_de_monture_terms) : '';
            $coloris_terms = wp_get_post_terms($lunetteId, 'coloris', array("fields" => "names"));
            $lunetteColor = !empty($coloris_terms) ? implode(',', $coloris_terms) : '';
            $product = wc_get_product($lunetteId);
            if ($product->is_type('variable')) {
                $variations = $product->get_available_variations();
                $lowest_price = null;
                foreach ($variations as $variation) {
                    $variation_obj = wc_get_product($variation['variation_id']);
                    // Priorise le prix réduit, puis le prix régulier
                    $variation_price = $variation_obj->get_sale_price() ?: $variation_obj->get_regular_price();
                    //$variation_price = $variation_obj->get_regular_price();
                    if (is_null($lowest_price) || $variation_price < $lowest_price) {
                        $lowest_price = $variation_price;
                    }
                }
                $lunettePrice = $lowest_price;
            } else {
                $lunettePrice = $product->get_sale_price() ?: $product->get_regular_price();
            }
            $lunetteColorImage = null;
            $attributes = $product->get_attributes();
            $color_images = [];

            if (isset($attributes['pa_couleurs'])) {
                $attribute = $attributes['pa_couleurs'];

                if ($attribute instanceof WC_Product_Attribute) {
                    $options = $attribute->get_options();
                    $isw_settings = get_option('isw_settings');
                    $color_index = isset($isw_settings['isw_attr']) ? array_search('pa_couleurs', $isw_settings['isw_attr']) : null;
                    $custom_colors = $color_index !== false ? ($isw_settings['isw_custom'][$color_index] ?? []) : [];

                    $couleurs = array_map(function ($term_id) use (&$color_images, $custom_colors) {
                        $term = get_term_by('id', $term_id, 'pa_couleurs');
                        if ($term) {
                            $color_name = $term->name;
                            $color_image = $custom_colors[strtolower($color_name)] ?? null;
                            if ($color_image) {
                                $color_images[strtolower($color_name)] = $color_image;
                                return $color_image;
                            }
                        }
                        return null;
                    }, $options);
                    $lunetteColorImage = reset($color_images); // Get the first color image
                }
            }
            $index = $key + 1;
            $jsonProductsArray["ov_product{$index}_name"] = $lunetteName;
            $jsonProductsArray["ov_product{$index}_link"] = $lunetteLink;
            $jsonProductsArray["ov_product{$index}_image"] = $lunetteImage;
            $jsonProductsArray["ov_product{$index}_shape"] = $lunetteShape;
            $jsonProductsArray["ov_product{$index}_color"] = $lunetteColorImage;
            $jsonProductsArray["ov_product{$index}_price"] = $lunettePrice;
        }
        $jsonProducts = json_encode($jsonProductsArray, JSON_PRETTY_PRINT);
        $jsonProducts = trim($jsonProducts, '{}');
        $data['ov_products'] = $jsonProducts;
    }

    $contactsGetResp = contactsGet($data,"customer");
    $contactsGetMag = contactsGet($data,"seller");
    if ($contactsGetResp['Success']) {
        if (!empty($contactsGetResp['Records']) && isset($contactsGetResp['Records'][0]['idContact'])) {
            $idContact = $contactsGetResp['Records'][0]['idContact'];
            $idContactMag = $contactsGetMag['Records'][0]['idContact'];
            logger("Get: idContact " . $idContact);
            logger("Get: idContactMag " . $idContactMag);
        } else {
            $contactsMergeResp = contactsMerge($data);
            if (!$contactsMergeResp['Success']) {
                logger("ErrorCode: " . print_r($contactsMergeResp['ErrorCode'], true));
                logger("ErrorMessage: " . print_r($contactsMergeResp['ErrorMessage'], true));
            } else {
                if (!empty($contactsMergeResp['Records']) && isset($contactsMergeResp['Records'][0]['IdRecord'])) {
                    $idContact = $contactsMergeResp['Records'][0]['IdRecord'];
                    $idContactMag = $contactsGetMag['Records'][0]['idContact'];
                    logger("Merge: idContact " . $idContact);
                    logger("Get: idContactMag " . $idContactMag);
                } else {
                    logger("Error: 'IdRecord' is missing from the merge response.");
                }
            }
        }
    } else {
        logger("ErrorCode: " . print_r($contactsGetResp['ErrorCode'], true));
        logger("ErrorMessage: " . print_r($contactsGetResp['ErrorMessage'], true));
        $contactsMergeResp = contactsMerge($data);
        if (!$contactsMergeResp['Success']) {
            logger("ErrorCode: " . print_r($contactsMergeResp['ErrorCode'], true));
            logger("ErrorMessage: " . print_r($contactsMergeResp['ErrorMessage'], true));
        } else {
            if (!empty($contactsMergeResp['Records']) && isset($contactsMergeResp['Records'][0]['IdRecord'])) {
                $idContact = $contactsMergeResp['Records'][0]['IdRecord'];
                $idContactMag = $contactsGetMag['Records'][0]['idContact'];
                logger("Merge: idContact " . $idContact);
                logger("Get: idContactMag " . $idContactMag);
            } else {
                logger("Error: 'IdRecord' is missing from the merge response.");
            }
        }
    }
    if (isset($idContact) && $idContact) {
        $data['idContact'] = $idContact;
        $data['idContactMag'] = $idContactMag;
        logger("Data: " . print_r($data, true));
        $sendSingle2RespToCustomer = sendingsSendSingle2($data, 'customer');
        if (!$sendSingle2RespToCustomer['Success']) {
            logger("SendSingle2 to customer: ErrorCode: " . print_r($sendSingle2RespToCustomer['ErrorCode'], true));
            logger("SendSingle2 to customer: ErrorMessage: " . print_r($sendSingle2RespToCustomer['ErrorMessage'], true));
        } else {
            logger("SendSingle2 to customer: Success");
        }
        $sendSingle2RespToSeller = sendingsSendSingle2($data, 'seller');
        if (!$sendSingle2RespToSeller['Success']) {
            logger("SendSingle2 to seller: ErrorCode: " . print_r($sendSingle2RespToSeller['ErrorCode'], true));
            logger("SendSingle2 to seller: ErrorMessage: " . print_r($sendSingle2RespToSeller['ErrorMessage'], true));
        } else {
            logger("SendSingle2 to seller: Success");
        }
    } else {
        logger("Error: no idContact.");
    }

    WC()->cart->empty_cart();
}
add_action('AmeliaAppointmentBookingAdded', 'syncDialogInsight', 20, 3);
