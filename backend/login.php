<?php
// Add these lines temporarily to display errors for debugging
// Remove or comment out in a production environment
error_reporting(E_ALL);
ini_set('display_errors', 1);
ini_set('log_errors', 1); // Also log errors to a file
ini_set('error_log', __DIR__ . '/login_errors.log'); // Specify a log file

header('Content-Type: application/json');
require_once 'dbconnect.php';

// Create an instance of the DBConnection class
$db = new DBConnection();

// Get the mysqli connection object
$conn = $db->getConnection();

// --- IMPORTANT: Check if the database connection was successful ---
if ($conn === null) {
    // Database connection failed in the constructor
    // The error should have been logged by DBConnection's constructor
    http_response_code(500); // Internal Server Error
    echo json_encode([
        'status' => 'error',
        'message' => 'Database service unavailable. Please try again later.'
        // Avoid exposing internal DB errors directly to the client
    ]);
    // No need to call $db->close() here, as the connection was never successfully established
    exit; // Stop script execution
}
// --- End of Important Check ---


// Get POST data
// Use $_SERVER['REQUEST_METHOD'] to ensure it's a POST request before accessing $_POST
$username = '';
$password = '';
if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $username = $_POST['username'] ?? '';
    $password = $_POST['password'] ?? '';
} else {
     // If it's not a POST request, you might want to handle that
     http_response_code(405); // Method Not Allowed
     $db->close(); // Close valid connection
     echo json_encode([
         'status' => 'error',
         'message' => 'Method not allowed. Only POST requests are accepted.'
     ]);
     exit;
}


if (empty($username) || empty($password)) {
    // Close connection before exiting
    $db->close();
    http_response_code(400); // Bad Request
    echo json_encode([
        'status' => 'error',
        'message' => 'Username and password are required'
    ]);
    exit;
}

// Query user using mysqli
// $conn is guaranteed to be a valid mysqli object here
$stmt = $conn->prepare('SELECT id, username, password, role FROM users WHERE username = ?');
// Check if prepare failed (due to invalid SQL, etc., not null connection)
if ($stmt === false) {
     $db->close();
     http_response_code(500); // Internal Server Error
     // Log this specific prepare error on the server
     error_log("Login Prepare failed: (" . $conn->errno . ") " . $conn->error);
     echo json_encode([
        'status' => 'error',
        'message' => 'An internal error occurred during login preparation.'
        // Avoid exposing raw SQL errors to the client
    ]);
    exit;
}
$stmt->bind_param("s", $username);
$execute_success = $stmt->execute();

// Check if execute failed
if ($execute_success === false) {
     $db->close();
     http_response_code(500); // Internal Server Error
     // Log this specific execute error on the server
     error_log("Login Execute failed: (" . $stmt->errno . ") " . $stmt->error);
     echo json_encode([
        'status' => 'error',
        'message' => 'An internal error occurred during login execution.'
    ]);
    exit;
}

$result = $stmt->get_result();
$user = $result->fetch_assoc(); // Fetch as associative array

$stmt->close(); // Close the statement


if ($user && password_verify($password, $user['password'])) {
    // Start session
    session_start();
    $_SESSION['user_id'] = $user['id'];
    $_SESSION['username'] = $user['username'];
    $_SESSION['role'] = $user['role'];

    $db->close(); // Close connection before successful exit
    http_response_code(200); // OK
    echo json_encode([
        'status' => 'success',
        'message' => 'Login successful',
        'data' => [
            'username' => $user['username'],
            'role' => $user['role']
        ]
    ]);
} else {
    $db->close(); // Close connection before failed exit
    http_response_code(401); // Unauthorized
    echo json_encode([
        'status' => 'error',
        'message' => 'Invalid username or password'
    ]);
}

// The connection is already closed in all successful/error paths using $db->close();
// This final close is redundant but harmless if $db->close() handles null.
// It's cleaner to ensure close is called before each exit.
// $db->close(); // Redundant here if exits are used

?>