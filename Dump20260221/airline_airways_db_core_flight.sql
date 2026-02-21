-- MySQL dump 10.13  Distrib 8.0.44, for Win64 (x86_64)
--
-- Host: localhost    Database: airline_airways_db
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
-- Table structure for table `core_flight`
--

DROP TABLE IF EXISTS `core_flight`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `core_flight` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `company_name` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `origin` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `destination` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `depart_at` datetime(6) NOT NULL,
  `arrive_at` datetime(6) NOT NULL,
  `return_at` datetime(6) DEFAULT NULL,
  `amount` decimal(10,2) NOT NULL,
  `trip_type` varchar(20) COLLATE utf8mb4_unicode_ci NOT NULL,
  `cabin_type` varchar(20) COLLATE utf8mb4_unicode_ci NOT NULL,
  `created_at` datetime(6) NOT NULL,
  `updated_at` datetime(6) NOT NULL,
  `repeat_type` varchar(20) COLLATE utf8mb4_unicode_ci NOT NULL,
  `repeat_days` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `is_active` tinyint(1) NOT NULL,
  `status` varchar(20) COLLATE utf8mb4_unicode_ci NOT NULL,
  `delay_hours` int unsigned DEFAULT NULL,
  `flight_number` varchar(20) COLLATE utf8mb4_unicode_ci NOT NULL,
  PRIMARY KEY (`id`),
  CONSTRAINT `core_flight_chk_1` CHECK ((`delay_hours` >= 0))
) ENGINE=InnoDB AUTO_INCREMENT=10 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `core_flight`
--

LOCK TABLES `core_flight` WRITE;
/*!40000 ALTER TABLE `core_flight` DISABLE KEYS */;
INSERT INTO `core_flight` VALUES (1,'IndiGo','Mumbai (BOM)','Kochi (COK)','2026-02-19 15:50:00.000000','2026-02-19 17:50:00.000000',NULL,9582.00,'one_way','first_class','2026-02-04 10:20:41.241683','2026-02-17 06:41:19.059054','daily','',1,'scheduled',NULL,'I-900'),(2,'Air India','Mumbai (BOM)','Bengaluru (BLR)','2026-02-19 18:51:00.000000','2026-02-19 21:51:00.000000',NULL,10500.00,'one_way','economy','2026-02-04 10:21:30.762329','2026-02-17 06:41:06.996226','daily','',1,'on_time',NULL,'AI-111'),(3,'Qatar Airways','Bengaluru (BLR)','Kochi (COK)','2026-02-26 02:53:00.000000','2026-02-26 16:51:00.000000','2026-02-26 20:52:00.000000',8500.00,'round_trip','economy','2026-02-04 10:22:30.995472','2026-02-17 06:40:53.947039','weekly','',1,'scheduled',NULL,'QA-548'),(4,'IndiGo','Mumbai (BOM)','Delhi (DEL)','2026-02-19 11:16:00.000000','2026-02-19 13:16:00.000000',NULL,4999.00,'one_way','economy','2026-02-05 05:46:23.055229','2026-02-17 06:42:46.032322','daily','',1,'scheduled',NULL,'I-901'),(5,'Air India','Mumbai (BOM)','Delhi (DEL)','2026-02-19 12:18:00.000000','2026-02-19 14:20:00.000000',NULL,4899.00,'one_way','economy','2026-02-05 05:47:44.666660','2026-02-17 06:40:27.749027','weekly','',1,'delayed',2,'AI-789'),(6,'Alliance Air','Lucknow (LKO)','Goa (GOI)','2026-02-13 13:25:00.000000','2026-02-14 13:25:00.000000','2026-02-14 13:25:00.000000',7000.00,'round_trip','business','2026-02-10 07:56:34.444097','2026-02-17 06:43:04.959642','custom','',1,'scheduled',NULL,'AA-120'),(7,'Saudia','Bengaluru (BLR)','Pune (PNQ)','2026-02-25 13:27:00.000000','2026-02-25 15:29:00.000000',NULL,8245.00,'one_way','premium_economy','2026-02-10 07:57:21.768416','2026-02-17 06:40:44.514549','weekly','',1,'scheduled',NULL,'S-123'),(8,'Lufthansa','Ahmedabad (AMD)','Pune (PNQ)','2026-02-19 13:27:00.000000','2026-02-20 13:27:00.000000',NULL,10000.00,'one_way','first_class','2026-02-10 07:57:47.137056','2026-02-17 06:42:33.847555','daily','',1,'scheduled',NULL,'L-987'),(9,'Singapore Airlines','Chennai (MAA)','Hyderabad (HYD)','2026-02-19 13:28:00.000000','2026-02-20 13:28:00.000000',NULL,4521.00,'one_way','economy','2026-02-10 07:58:14.346186','2026-02-17 06:42:11.638683','daily','',1,'scheduled',NULL,'SA-147');
/*!40000 ALTER TABLE `core_flight` ENABLE KEYS */;
UNLOCK TABLES;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2026-02-21  9:52:52
