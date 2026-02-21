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
-- Table structure for table `utility_bill`
--

DROP TABLE IF EXISTS `utility_bill`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `utility_bill` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `utility_type` varchar(50) COLLATE utf8mb4_unicode_ci NOT NULL,
  `bill_id` varchar(64) COLLATE utf8mb4_unicode_ci NOT NULL,
  `consumer_name` varchar(150) COLLATE utf8mb4_unicode_ci NOT NULL,
  `consumer_id` varchar(150) COLLATE utf8mb4_unicode_ci NOT NULL,
  `previous_reading` decimal(12,2) DEFAULT NULL,
  `current_reading` decimal(12,2) DEFAULT NULL,
  `total_amount` decimal(12,2) DEFAULT NULL,
  `created_at` datetime(6) NOT NULL,
  PRIMARY KEY (`id`),
  KEY `utility_bil_utility_e33429_idx` (`utility_type`),
  KEY `utility_bil_bill_id_f4dfcc_idx` (`bill_id`)
) ENGINE=InnoDB AUTO_INCREMENT=7 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `utility_bill`
--

LOCK TABLES `utility_bill` WRITE;
/*!40000 ALTER TABLE `utility_bill` DISABLE KEYS */;
INSERT INTO `utility_bill` VALUES (1,'Electricity','KSEB-20260118220748','anjana','1098',788.00,1025.00,1896.00,'2026-01-18 16:39:09.381236'),(2,'Electricity','KSEB-20260129102242','achu','1234',100.00,200.00,800.00,'2026-01-29 04:56:00.258612'),(3,'Water','KWA-20260129125640','achu','787',222.00,250.00,280.00,'2026-01-29 07:27:41.428471'),(4,'WiFi','KSEB-20260129143403','anjana','555',NULL,NULL,799.00,'2026-01-29 09:04:47.944205'),(5,'Electricity','KSEB-20260220183702','achu','1234',200.00,300.00,800.00,'2026-02-20 13:07:52.831884'),(6,'Electricity','KSEB-20260220184521','anjana','1098',100.00,300.00,1600.00,'2026-02-20 13:16:12.682716');
/*!40000 ALTER TABLE `utility_bill` ENABLE KEYS */;
UNLOCK TABLES;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2026-02-21 10:12:08
