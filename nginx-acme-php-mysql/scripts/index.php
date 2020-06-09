<?php

$db_name = $_SERVER['MYSQL_DATABASE'] ?? '';
$db_user = $_SERVER['MYSQL_USER'] ?? '';
$db_password = $_SERVER['MYSQL_PASSWORD'] ?? '';
if (!$db_name || !$db_user || !$db_password) {
    header('HTTP/1.1 500 Configuration error');
    echo 'Missing database credentials';
    exit;
}
$options = [PDO::MYSQL_ATTR_INIT_COMMAND => 'SET NAMES utf8'];

try {
    $pdo = new PDO('mysql:host=database;dbname=' . $db_name, $db_user, $db_password, $options);
    $pdo->exec('UPDATE T SET `counter`=`counter`+1');
    $counter = $pdo->query('SELECT `counter` FROM T')->fetchColumn(0);
}catch (Exception $E){
    header('HTTP/1.1 500 Database error');
    echo 'Some database-related error';
    exit;
}

echo 'Counter: ',$counter;
