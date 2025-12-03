<?php

function logger($string)
{
    $log_message = date('Y-m-d H:i:s') . " - " . $string . "\n";
    file_put_contents(plugin_dir_path(__FILE__) . '../response.txt', $log_message, FILE_APPEND);
}

function loggerLOG($string)
{
    $log_message = date('Y-m-d H:i:s') . " - " . $string . "\n";
    file_put_contents(plugin_dir_path(__FILE__) . '../response.log', $log_message, FILE_APPEND);
}
