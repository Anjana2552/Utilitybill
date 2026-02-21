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
-- Table structure for table `core_foodvenue`
--

DROP TABLE IF EXISTS `core_foodvenue`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `core_foodvenue` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `name` varchar(200) COLLATE utf8mb4_unicode_ci NOT NULL,
  `location` varchar(200) COLLATE utf8mb4_unicode_ci NOT NULL,
  `cuisine` varchar(120) COLLATE utf8mb4_unicode_ci NOT NULL,
  `menu_text` longtext COLLATE utf8mb4_unicode_ci NOT NULL,
  `avg_rate` decimal(10,2) NOT NULL,
  `seats_available` int unsigned NOT NULL,
  `open_hours` varchar(120) COLLATE utf8mb4_unicode_ci NOT NULL,
  `is_active` tinyint(1) NOT NULL,
  `created_at` datetime(6) NOT NULL,
  `updated_at` datetime(6) NOT NULL,
  PRIMARY KEY (`id`),
  CONSTRAINT `core_foodvenue_chk_1` CHECK ((`seats_available` >= 0))
) ENGINE=InnoDB AUTO_INCREMENT=8 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `core_foodvenue`
--

LOCK TABLES `core_foodvenue` WRITE;
/*!40000 ALTER TABLE `core_foodvenue` DISABLE KEYS */;
INSERT INTO `core_foodvenue` VALUES (2,'Cococart & Cafe','T1,Level 1','','',0.00,150,'12Am - 11;30 PM',1,'2026-02-10 09:22:44.963075','2026-02-10 09:22:44.963075'),(3,'Cafe on the go','T1,Level 0','','',0.00,120,'12 Am - 11:59 PM',1,'2026-02-10 09:37:50.479307','2026-02-10 09:53:16.816186'),(4,'Jam','T1,Level 1','','',0.00,100,'12 Am - 11:59 PM',1,'2026-02-10 09:40:46.961633','2026-02-10 09:40:46.961633'),(5,'Malabar Express','T1,Level 1','','',0.00,100,'12 Am - 11:59 PM',1,'2026-02-10 09:59:49.568674','2026-02-10 09:59:49.568674'),(6,'Cafeccino Express','T1,Level 1','','',0.00,150,'12 Am - 11:59 PM',1,'2026-02-11 04:40:34.778070','2026-02-11 04:40:34.778070'),(7,'Theobroma','T1,Level 1','','',0.00,120,'12 Am - 11:59 PM',1,'2026-02-11 04:55:19.023787','2026-02-11 04:55:19.023787');
/*!40000 ALTER TABLE `core_foodvenue` ENABLE KEYS */;
UNLOCK TABLES;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2026-02-21  9:52:51
