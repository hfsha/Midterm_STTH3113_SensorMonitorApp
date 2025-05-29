<?php
class DBConnection {
    private $host = 'localhost';
    private $user = 'humancmt_hfsha_dht11_admin';
    private $pass = 'VndN#syyYPj@';
    private $dbname = 'humancmt_hfsha_dht11';
    private $conn;

    public function __construct() {
        // Set reporting for connection errors temporarily to capture details
        mysqli_report(MYSQLI_REPORT_ERROR | MYSQLI_REPORT_STRICT);

        try {
            $this->conn = new mysqli($this->host, $this->user, $this->pass, $this->dbname);
            $this->conn->set_charset("utf8mb4");
        } catch (mysqli_sql_exception $e) {
            // Log the connection error
            $this->logError("Connection failed: " . $e->getMessage());
            // Set conn to null on failure instead of dying
            $this->conn = null;
        } finally {
             // Revert mysqli reporting to default after attempting connection
            mysqli_report(MYSQLI_REPORT_ERROR);
        }
    }

    public function getConnection() {
        return $this->conn;
    }

    public function close() {
        if ($this->conn !== null) {
            $this->conn->close();
            $this->conn = null; // Set to null after closing
        }
    }

    public function insertDHTData($device_id, $temperature, $humidity, $relay_status) {
        if ($this->conn === null) {
            $this->logError("DBConnection::insertDHTData called with no active connection.");
            return false;
        }
        // Assuming your sensor data table is tbl_dht11 based on your original insertDHTData
        $stmt = $this->conn->prepare("INSERT INTO tbl_dht11 (device_id, temperature, humidity, relay_status) VALUES (?, ?, ?, ?)");

        if ($stmt === false) {
            $this->logError("Prepare failed in insertDHTData: (" . $this->conn->errno . ") " . $this->conn->error);
            return false;
        }

        $stmt->bind_param("idds", $device_id, $temperature, $humidity, $relay_status);
        $result = $stmt->execute();

        if ($result === false) {
             $this->logError("Execute failed in insertDHTData: (" . $stmt->errno . ") " . $stmt->error);
        }

        $stmt->close();
        return $result; // Returns true on success, false on failure
    }

    // Method to get the latest sensor readings
    public function getLatestReadings($device_id, $limit = 50) {
         if ($this->conn === null) {
            $this->logError("DBConnection::getLatestReadings called with no active connection.");
            return []; // Return empty array if no connection
        }

        // Assuming your sensor data table is tbl_dht11
        $stmt = $this->conn->prepare("SELECT * FROM tbl_dht11 WHERE device_id = ? ORDER BY created_at DESC LIMIT ?");

         if ($stmt === false) {
            $this->logError("Prepare failed in getLatestReadings: (" . $this->conn->errno . ") " . $this->conn->error);
            return [];
        }

        $stmt->bind_param("ii", $device_id, $limit);
        $stmt->execute();
        $result = $stmt->get_result();
        $data = $result->fetch_all(MYSQLI_ASSOC);
        $stmt->close();
        return array_reverse($data); // Oldest first for charts
    }

    // Method to fetch thresholds from tbl_threshold
    // Assumes a single row for thresholds, typically with a fixed ID (e.g., id=1)
    public function getThresholds() {
        if ($this->conn === null) {
            $this->logError("DBConnection::getThresholds called with no active connection.");
            return ["temp_threshold" => 26.0, "hum_threshold" => 70.0]; // Return defaults
        }

        // Adjust query if your threshold row logic is different
        $sql = "SELECT temp_threshold, hum_threshold FROM tbl_threshold WHERE id = 1 LIMIT 1";
        $result = $this->conn->query($sql);

        if ($result === false) {
             $this->logError("Query failed in getThresholds: (" . $this->conn->errno . ") " . $this->conn->error);
             return ["temp_threshold" => 26.0, "hum_threshold" => 70.0]; // Return defaults on query failure
        }

        if ($result->num_rows > 0) {
            $thresholds = $result->fetch_assoc();
            $result->free(); // Free result set memory
            return $thresholds; // Return the fetched thresholds
        } else {
            // Return default values if no row is found
            return ["temp_threshold" => 26.0, "hum_threshold" => 70.0];
        }
    }

    // Method to update or insert thresholds into tbl_threshold
    // Uses REPLACE INTO assuming id=1 for the single row
    public function setThresholds($temp, $hum) {
         if ($this->conn === null) {
            $this->logError("DBConnection::setThresholds called with no active connection.");
            return false;
        }

        // Using REPLACE INTO to insert or update the single row with id=1
        // Make sure 'id' is a primary key in your tbl_threshold
        $sql = $this->conn->prepare("REPLACE INTO tbl_threshold (id, temp_threshold, hum_threshold, updated_at) VALUES (1, ?, ?, NOW())");

        if ($sql === false) {
            $this->logError("Prepare failed in setThresholds: (" . $this->conn->errno . ") " . $this->conn->error);
            return false;
        }

        $sql->bind_param("dd", $temp, $hum); // 'd' for double/float

        $result = $sql->execute();

        if ($result === false) {
             $this->logError("Execute failed in setThresholds: (" . $sql->errno . ") " . $sql->error);
        }

        $sql->close();
        return $result; // Returns true on success, false on failure
    }

    private function logError($message) {
        $log_file = __DIR__ . '/dberrors.log';
        $timestamp = date("[Y-m-d H:i:s]");
        error_log("$timestamp $message\n", 3, $log_file);
    }
}
?>