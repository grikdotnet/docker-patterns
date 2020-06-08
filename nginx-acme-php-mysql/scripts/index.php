<?php

$db_name = $_SERVER['MYSQL_DATABASE'];
$db_user = $_SERVER['MYSQL_USER'];
$db_password = $_SERVER['MYSQL_PASSWORD'];
$options = [PDO::MYSQL_ATTR_INIT_COMMAND => 'SET NAMES utf8'];
$pdo = new PDO('mysql:host=database;dbname='.$db_name,$db_user,$db_password,$options);
