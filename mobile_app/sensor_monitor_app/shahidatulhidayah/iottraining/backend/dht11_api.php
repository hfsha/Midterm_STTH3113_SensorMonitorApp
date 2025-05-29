<?php
require_once 'dbconnect.php';

// Security headers
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('X-Content-Type-Options: nosniff');

// Rate limiting (1 request per 2 seconds per IP)
session_start();
if (isset($_SESSION['last_request']) && (microtime(true) - $_SESSION['last_request'] < 2)) {
    http_response_code(429);
    die(json_encode(["status" => "error", "message" => "Too many requests"]));
}
$_SESSION['last_request'] = microtime(true);

$db = null; // Initialize $db to null

try {
    $db = new DBConnection(); // Initialize DB connection

    // Check if database connection was successful
    if ($db->getConnection() === null) {
        http_response_code(500);
        die(json_encode(["status" => "error", "message" => "Database connection failed."]));
    }

    // --- Handle Threshold Updates (from Mobile App via POST) ---
    if ($_SERVER['REQUEST_METHOD'] === 'POST') {
        // Validate required parameters for threshold update
        $required_post = ['temp_threshold', 'hum_threshold'];
        foreach ($required_post as $param) {
            if (!isset($_POST[$param])) {
                http_response_code(400);
                die(json_encode(["status" => "error", "message" => "Missing POST parameter: $param"]));
            }
        }
        
        // Sanitize and validate threshold inputs
        $newTempThreshold = filter_var($_POST['temp_threshold'], FILTER_VALIDATE_FLOAT);
        $newHumThreshold = filter_var($_POST['hum_threshold'], FILTER_VALIDATE_FLOAT);
        
        if ($newTempThreshold === false || $newHumThreshold === false || $newTempThreshold < -40 || $newTempThreshold > 80 || $newHumThreshold < 0 || $newHumThreshold > 100) {
            http_response_code(400);
            die(json_encode(["status" => "error", "message" => "Invalid threshold values"]));
        }

        // Update thresholds in the database
        if ($db->setThresholds($newTempThreshold, $newHumThreshold)) { // Assuming setThresholds method exists
            echo json_encode(["status" => "success", "message" => "Thresholds updated successfully."]);
        } else {
            http_response_code(500);
            echo json_encode(["status" => "error", "message" => "Database error updating thresholds."]);
        }
        
        // exit; // Let the finally block handle closing connection
    }

    // --- Handle Sensor Data (from Arduino via GET) ---
    // This block is executed if it's not a POST request
    else { // Assuming GET or other method for sensor data

        // Validate required parameters for sensor data
        $required_get = ['id', 'temp', 'hum', 'relay'];
        foreach ($required_get as $param) {
            if (!isset($_GET[$param])) {
                http_response_code(400);
                die(json_encode(["status" => "error", "message" => "Missing GET parameter: $param"]));
            }
        }

        // Sanitize inputs
        $device_id = (int)$_GET['id'];
        $temperature = (float)$_GET['temp'];
        $humidity = (float)$_GET['hum'];
        $relay_status = in_array($_GET['relay'], ['On', 'Off']) ? $_GET['relay'] : 'Off';

        // Validate ranges
        if ($temperature < -40 || $temperature > 80 || $humidity < 0 || $humidity > 100) {
            http_response_code(400);
            die(json_encode(["status" => "error", "message" => "Invalid sensor values"]));
        }

        // Process data
        if ($db->insertDHTData($device_id, $temperature, $humidity, $relay_status)) { // Assuming insertDHTData method exists
            // Fetch the latest thresholds after successful data insertion
            $thresholds = $db->getThresholds(); // Assuming getThresholds method exists
            echo json_encode([
                "status" => "success",
                "data" => [
                    "device_id" => $device_id,
                    "temperature" => $temperature,
                    "humidity" => $humidity,
                    "relay_status" => $relay_status,
                    "timestamp" => date("Y-m-d H:i:s"),
                    "temp_threshold" => $thresholds['temp_threshold'],
                    "hum_threshold" => $thresholds['hum_threshold']
                ]
            ]);
        } else {
             http_response_code(500);
             echo json_encode(["status" => "error", "message" => "Database error inserting sensor data."]);
        }
    }

} catch (Exception $e) {
    // Catch any exceptions and return a JSON error
    http_response_code(500);
    echo json_encode([
        "status" => "error",
        "message" => "Server error: " . $e->getMessage(),
        // Optional: include more details in development, but be cautious in production
        // "trace": $e->getTraceAsString()
    ]);
} finally {
    // Ensure the database connection is closed if it was opened
    if ($db !== null) {
        $db->close();
    }
}

?> 