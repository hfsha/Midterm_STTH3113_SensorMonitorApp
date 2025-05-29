<?php
header('Content-Type: application/json');
require_once 'dbconnect.php';

// Create an instance of the DBConnection class
$db = new DBConnection();
// Get the mysqli connection object
$conn = $db->getConnection();

// Get POST data
$username = $_POST['username'] ?? '';
$password = $_POST['password'] ?? '';

if (empty($username) || empty($password)) {
    // Close connection before exiting
    $db->close();
    echo json_encode([
        'status' => 'error',
        'message' => 'Username and password are required'
    ]);
    exit;
}

// Check if username already exists using mysqli
$stmt = $conn->prepare('SELECT id FROM users WHERE username = ?');
// Check if prepare failed
if ($stmt === false) {
     $db->close();
     echo json_encode([
        'status' => 'error',
        'message' => 'Prepare failed: ' . $conn->error
    ]);
    exit;
}
$stmt->bind_param("s", $username);
$stmt->execute();
$stmt->store_result(); // Store the result to check number of rows

if ($stmt->num_rows > 0) {
    $stmt->close();
    $db->close();
    echo json_encode([
        'status' => 'error',
        'message' => 'Username already exists'
    ]);
    exit;
}
$stmt->close(); // Close the statement after checking existence

// Hash the password
$hashed_password = password_hash($password, PASSWORD_BCRYPT);

// Insert new user using mysqli
$stmt = $conn->prepare('INSERT INTO users (username, password, role) VALUES (?, ?, \'user\')');
// Check if prepare failed
if ($stmt === false) {
     $db->close();
     echo json_encode([
        'status' => 'error',
        'message' => 'Prepare failed: ' . $conn->error
    ]);
    exit;
}
$stmt->bind_param("ss", $username, $hashed_password);

if ($stmt->execute()) {
    $stmt->close();
    $db->close();
    echo json_encode([
        'status' => 'success',
        'message' => 'Registration successful. Please login.'
    ]);
} else {
    // Get and include the detailed database error message using mysqli error
    $error_message = $stmt->error;
    $stmt->close();
    $db->close();
    echo json_encode([
        'status' => 'error',
        'message' => 'Registration failed: ' . ($error_message ?? 'Unknown database error')
    ]);
}

// Close the database connection
$db->close();
?>