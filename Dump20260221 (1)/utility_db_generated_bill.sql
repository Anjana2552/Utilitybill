-- MySQL dump 10.13  Distrib 8.0.44, for Win64 (x86_64)
--
-- Host: localhost    Database: utility_db
-- ------------------------------------------------------
-- Server version	8.0.44

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!50503 SET NAMES utf8 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;

--
-- Table structure for table `generated_bill`
--

DROP TABLE IF EXISTS `generated_bill`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `generated_bill` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `bill_id` varchar(64) COLLATE utf8mb4_unicode_ci NOT NULL,
  `utility_type` varchar(50) COLLATE utf8mb4_unicode_ci NOT NULL,
  `provider_name` varchar(150) COLLATE utf8mb4_unicode_ci NOT NULL,
  `consumer_name` varchar(150) COLLATE utf8mb4_unicode_ci NOT NULL,
  `consumer_number` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
  `water_connection_number` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
  `gas_consumer_id` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
  `wifi_consumer_id` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
  `dth_subscriber_id` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
  `plan_name` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
  `dth_package_name` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
  `specified_utility_type` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
  `previous_reading` decimal(12,2) DEFAULT NULL,
  `current_reading` decimal(12,2) DEFAULT NULL,
  `units_consumed` decimal(12,2) DEFAULT NULL,
  `rate_per_unit` decimal(12,2) DEFAULT NULL,
  `total_amount` decimal(12,2) DEFAULT NULL,
  `reading_date` date NOT NULL,
  `due_date` date NOT NULL,
  `created_at` datetime(6) NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `bill_id` (`bill_id`),
  KEY `generated_b_utility_da1d57_idx` (`utility_type`),
  KEY `generated_b_bill_id_c7faca_idx` (`bill_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `generated_bill`
--

LOCK TABLES `generated_bill` WRITE;
/*!40000 ALTER TABLE `generated_bill` DISABLE KEYS */;
/*!40000 ALTER TABLE `generated_bill` ENABLE KEYS */;
UNLOCK TABLES;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2026-02-21 10:12:07
