<?php
require_once 'dbconnect.php';

// Security headers
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('X-Frame-Options: DENY');

// --- TEMPORARY: Enable error display for debugging ---
// REMOVE OR COMMENT OUT THESE LINES IN PRODUCTION
ini_set('display_errors', 1);
ini_set('display_startup_errors', 1);
error_reporting(E_ALL);
// --- END TEMPORARY DEBUGGING CODE ---


// Get parameters with defaults
$device_id = isset($_GET['device_id']) ? (int)$_GET['device_id'] : 101;
$limit = min(isset($_GET['limit']) ? (int)$_GET['limit'] : 50, 1000);

$db = null; // Initialize $db to null

try {
    $db = new DBConnection();

    // Check if database connection was successful (Assuming DBConnection has a method like getConnection)
    if ($db->getConnection() === null) {
         http_response_code(500);
         // Log the specific database connection error for debugging
         error_log("Database connection failed in dht11_fetch.php");
         die(json_encode(["status" => "error", "message" => "Database connection failed."]));
    }

    // Fetch sensor data
    $data = $db->getLatestReadings($device_id, $limit);

    // Fetch thresholds (assuming getThresholds method exists in DBConnection)
    // Pass device_id to getThresholds if it's device-specific
    $thresholds = $db->getThresholds($device_id);

    // Prepare response data
    $responseData = [
        "status" => "success",
        "device_id" => $device_id,
        "count" => count($data),
        "data" => $data
    ];

    // Add thresholds to the response if fetched successfully
    // Check if $thresholds is a valid array and contains the expected keys
    if ($thresholds !== null && is_array($thresholds) && isset($thresholds['temp_threshold']) && isset($thresholds['hum_threshold'])) {
        $responseData["temp_threshold"] = (float) $thresholds['temp_threshold']; // Ensure float type
        $responseData["hum_threshold"] = (float) $thresholds['hum_threshold'];   // Ensure float type
    } else {
         // Log a warning if thresholds could not be fetched or were in an unexpected format
         error_log("Could not fetch or find thresholds for device ID: $device_id in dht11_fetch.php. Response: " . json_encode($thresholds));
         // Optionally, you could add default threshold values here if fetching fails
         // $responseData["temp_threshold"] = 26.0;
         // $responseData["hum_threshold"] = 70.0;
         // Note: If you add defaults here, ensure Flutter handles cases where thresholds are missing from the JSON
    }


    // Return success response with data and thresholds
    echo json_encode($responseData);

} catch (Exception $e) {
    // Log the specific exception message for debugging
    error_log("Exception in dht11_fetch.php: " . $e->getMessage());
    // Return error response
    http_response_code(500);
    echo json_encode(["status" => "error", "message" => "Failed to fetch data: " . $e->getMessage()]); // Include error message for debugging
} finally {
    // Ensure database connection is closed even if an error occurs
    if ($db !== null) {
        $db->close();
    }
}
?>