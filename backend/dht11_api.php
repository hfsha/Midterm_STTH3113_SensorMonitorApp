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

$db = null;

try {
    $db = new DBConnection();

    if ($db->getConnection() === null) {
        http_response_code(500);
        error_log("Database connection failed in dht11_api.php");
        die(json_encode(["status" => "error", "message" => "Database connection failed."]));
    }

    // --- Handle Threshold Updates (from Mobile App via POST) ---
    if ($_SERVER['REQUEST_METHOD'] === 'POST') {
        $json_data = file_get_contents('php://input');
        $request_data = json_decode($json_data, true);

        if ($request_data === null) {
            http_response_code(400);
            die(json_encode(["status" => "error", "message" => "Invalid JSON data received."]));
        }

        $required_post = ['temp_threshold', 'hum_threshold'];
        foreach ($required_post as $param) {
            if (!isset($request_data[$param])) {
                http_response_code(400);
                die(json_encode(["status" => "error", "message" => "Missing JSON parameter: $param"]));
            }
        }

        $newTempThreshold = filter_var($request_data['temp_threshold'], FILTER_VALIDATE_FLOAT);
        $newHumThreshold = filter_var($request_data['hum_threshold'], FILTER_VALIDATE_FLOAT);

        if ($newTempThreshold === false || $newHumThreshold === false || $newTempThreshold < -40 || $newTempThreshold > 80 || $newHumThreshold < 0 || $newHumThreshold > 100) {
            http_response_code(400);
            die(json_encode(["status" => "error", "message" => "Invalid threshold values"]));
        }

        if ($db->setThresholds($newTempThreshold, $newHumThreshold)) {
            echo json_encode(["status" => "success", "message" => "Thresholds updated successfully."]);
        } else {
            error_log("Database error updating thresholds in dht11_api.php");
            http_response_code(500);
            echo json_encode(["status" => "error", "message" => "Database error updating thresholds."]);
        }
    }
    // --- Handle Sensor Data (from Arduino via GET) ---
    else {
        // If only fetching thresholds (e.g., on Arduino startup)
        if (isset($_GET['fetch_thresholds'])) {
            $thresholds = $db->getThresholds();
            echo json_encode([
                "status" => "success",
                "data" => [
                    "temp_threshold" => $thresholds["temp_threshold"] ?? 26.0,
                    "hum_threshold" => $thresholds["hum_threshold"] ?? 70.0
                ]
            ]);
            exit;
        }

        $required_get = ['id', 'temp', 'hum', 'relay'];
        foreach ($required_get as $param) {
            if (!isset($_GET[$param])) {
                http_response_code(400);
                die(json_encode(["status" => "error", "message" => "Missing GET parameter: $param"]));
            }
        }

        $device_id = (int)$_GET['id'];
        $temperature = filter_var($_GET['temp'], FILTER_VALIDATE_FLOAT);
        $humidity = filter_var($_GET['hum'], FILTER_VALIDATE_FLOAT);
        $relay_status = in_array($_GET['relay'], ['On', 'Off']) ? $_GET['relay'] : 'Off';

        if ($temperature === false || $humidity === false || $temperature < -40 || $temperature > 80 || $humidity < 0 || $humidity > 100) {
            http_response_code(400);
            die(json_encode(["status" => "error", "message" => "Invalid sensor values or failed sanitization"]));
        }

        if ($db->insertDHTData($device_id, $temperature, $humidity, $relay_status)) {
            $thresholds = $db->getThresholds();
            echo json_encode([
                "status" => "success",
                "data" => [
                    "device_id" => $device_id,
                    "temperature" => $temperature,
                    "humidity" => $humidity,
                    "relay_status" => $relay_status,
                    "timestamp" => date("Y-m-d H:i:s"),
                    "temp_threshold" => $thresholds["temp_threshold"] ?? 26.0,
                    "hum_threshold" => $thresholds["hum_threshold"] ?? 70.0
                ]
            ]);
        } else {
            error_log("Database error inserting DHT data in dht11_api.php");
            http_response_code(500);
            echo json_encode(["status" => "error", "message" => "Database error inserting sensor data"]);
        }
    }

} catch (Exception $e) {
    error_log("Uncaught Exception in dht11_api.php: " . $e->getMessage());
    http_response_code(500);
    echo json_encode(["status" => "error", "message" => "An unexpected server error occurred."]);
} finally {
    if ($db !== null) {
        $db->close();
    }
}
?>