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
-- Table structure for table `user_utility`
--

DROP TABLE IF EXISTS `user_utility`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `user_utility` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `user_name` varchar(150) COLLATE utf8mb4_unicode_ci NOT NULL,
  `utility_type` varchar(50) COLLATE utf8mb4_unicode_ci NOT NULL,
  `provider_name` varchar(150) COLLATE utf8mb4_unicode_ci NOT NULL,
  `consumr_number` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
  `water_connection_number` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
  `gas_connection_number` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
  `wifi_consumer_id` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
  `dth_subscriber_id` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
  `meter_number` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
  `connection_type` varchar(50) COLLATE utf8mb4_unicode_ci NOT NULL,
  `plan_name` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
  `is_active` tinyint(1) NOT NULL,
  `creeated_at` datetime(6) NOT NULL,
  `user_id` int DEFAULT NULL,
  `house_number` varchar(50) COLLATE utf8mb4_unicode_ci NOT NULL,
  PRIMARY KEY (`id`),
  KEY `user_utility_user_id_6afa0c1b_fk_auth_user_id` (`user_id`),
  KEY `user_utilit_utility_1b1218_idx` (`utility_type`),
  KEY `user_utilit_user_na_d85a3d_idx` (`user_name`),
  CONSTRAINT `user_utility_user_id_6afa0c1b_fk_auth_user_id` FOREIGN KEY (`user_id`) REFERENCES `auth_user` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=25 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `user_utility`
--

LOCK TABLES `user_utility` WRITE;
/*!40000 ALTER TABLE `user_utility` DISABLE KEYS */;
INSERT INTO `user_utility` VALUES (2,'anjana','Electricity','KSEB','1098','','','','','1234','Domestic','',1,'2026-01-16 17:13:59.879386',2,''),(3,'achu','Water','Water','','124','','','','589','Domestic','',1,'2026-01-18 10:31:20.994129',7,''),(4,'achu','Electricity','KSEB','1234','','','','','111','Domestic','',1,'2026-01-18 10:31:45.618081',7,''),(5,'anjana','Water','KWA','','8549','','','','1234','Domestic','',1,'2026-01-24 05:28:05.035828',2,''),(6,'User','Gas','LPG','','','898','','','777','','',1,'2026-01-27 16:18:57.619577',NULL,''),(7,'akash','Gas','LPG','','','789','','','562','','',1,'2026-01-27 16:48:09.211465',NULL,''),(8,'akash','DTH','BSNL','','','','','888','562','','457',1,'2026-01-27 16:49:20.838425',NULL,''),(9,'anjana','Wifi','Kerala vision','','','','555','','1234','','200 Mbps',1,'2026-01-28 05:25:02.624172',2,''),(10,'User','Electricity','KSEB','555','','','','','888','Domestic','',1,'2026-01-29 04:50:10.728798',NULL,''),(11,'sanju','DTH','Asianet','','','','','7777','777','','1 month',1,'2026-01-29 06:18:31.401373',12,''),(12,'sanju','Electricity','KSEB','9875','','','','','777','Domestic','',1,'2026-01-29 06:18:58.385041',12,''),(13,'sanju','Water','KWA','','968','','','','777','Domestic','',1,'2026-01-29 06:19:45.935573',12,''),(14,'sanju','Wifi','BSNL','','','','854','','777','','300 Mbps',1,'2026-01-29 06:20:07.111910',12,''),(15,'arya','Gas','LPG','','','985','','','151','','',1,'2026-01-31 10:24:08.240927',10,''),(16,'arya','DTH','Kerala vision','','','','','2596','151','','1 month',1,'2026-01-31 10:25:13.640785',10,''),(17,'arya','Electricity','KSEB','3232','','','','','151','Domestic','',1,'2026-01-31 10:25:44.829698',10,''),(18,'achu','Wifi','Kerala Vision','','','','147','','111','','300 Mbps',1,'2026-02-18 15:38:44.957842',7,''),(19,'achu','Gas','Bharath Gas','','','7775','','','111','','',1,'2026-02-18 15:40:44.585760',7,''),(20,'anjana','EMI','BAJAJ','','','','','','1234','','',1,'2026-02-18 15:43:32.123376',2,''),(21,'rinu','Water','KWA','','5554','','','','363','Commercial','',1,'2026-02-18 15:49:34.305334',11,''),(22,'rinu','Wifi','BSNL','','','','454','','363','','200 Mbps',1,'2026-02-18 15:49:56.507448',11,''),(23,'rinu','DTH','Kerala Vision','','','','','444','363','','1 Month',1,'2026-02-18 15:50:38.020771',11,''),(24,'anjana','DTH','Kerala vision','','','','','7895','1234','','1 month',1,'2026-02-21 10:49:28.177921',2,'1234');
/*!40000 ALTER TABLE `user_utility` ENABLE KEYS */;
UNLOCK TABLES;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2026-02-24  9:48:19
