<?php

$db_name = $_SERVER['DB_NAME'];
$db_user = $_SERVER['DB_USER'];
$db_password = $_SERVER['DB_PASSWORD'];
$options = [PDO::MYSQL_ATTR_INIT_COMMAND => 'SET NAMES utf8'];
$pdo = new PDO('mysql:host=database;dbname='.$db_name,$db_user,$db_password,$options);
