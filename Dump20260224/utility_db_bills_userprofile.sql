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
-- Table structure for table `bills_userprofile`
--

DROP TABLE IF EXISTS `bills_userprofile`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `bills_userprofile` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `phone` varchar(20) COLLATE utf8mb4_unicode_ci NOT NULL,
  `address` longtext COLLATE utf8mb4_unicode_ci NOT NULL,
  `created_at` datetime(6) NOT NULL,
  `updated_at` datetime(6) NOT NULL,
  `user_id` int NOT NULL,
  `role` varchar(20) COLLATE utf8mb4_unicode_ci NOT NULL,
  `email` varchar(254) COLLATE utf8mb4_unicode_ci NOT NULL,
  `full_name` varchar(150) COLLATE utf8mb4_unicode_ci NOT NULL,
  `otp_code` varchar(6) COLLATE utf8mb4_unicode_ci NOT NULL,
  `otp_expires_at` datetime(6) DEFAULT NULL,
  `otp_verified` tinyint(1) NOT NULL,
  `house_number` varchar(50) COLLATE utf8mb4_unicode_ci NOT NULL,
  `utility_type` varchar(50) COLLATE utf8mb4_unicode_ci NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `user_id` (`user_id`),
  CONSTRAINT `bills_userprofile_user_id_0726e2f9_fk_auth_user_id` FOREIGN KEY (`user_id`) REFERENCES `auth_user` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=18 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `bills_userprofile`
--

LOCK TABLES `bills_userprofile` WRITE;
/*!40000 ALTER TABLE `bills_userprofile` DISABLE KEYS */;
INSERT INTO `bills_userprofile` VALUES (2,'','','2026-01-07 07:10:05.546000','2026-02-22 09:35:09.305898',2,'user','anjana@gmail.com','Anjana','',NULL,0,'1234',''),(3,'','','2026-01-07 07:16:42.636000','2026-01-07 07:16:42.645000',3,'admin','admin@gmail.com','admin','',NULL,0,'',''),(6,'9002213256','KSEB\nAdoor','2026-01-17 16:18:04.088700','2026-02-23 05:40:10.596444',6,'utility','amalkseb@gmail.com','Amal KSEB','',NULL,0,'','Electricity'),(7,'','','2026-01-18 10:28:17.614412','2026-01-18 10:28:17.614412',7,'user','achu@gmail.com','achu','',NULL,1,'',''),(8,'9889855889','KWA\nAdoor','2026-01-18 12:35:19.888512','2026-02-23 05:40:10.609653',8,'utility','appukwa@gmail.com','Appu','',NULL,0,'','Water'),(10,'','','2026-01-29 04:44:54.670120','2026-01-29 04:44:54.670120',10,'user','arya@gmail.com','arya','',NULL,1,'',''),(11,'','','2026-01-29 05:52:54.773498','2026-01-29 05:52:54.773498',11,'user','rinu@gmail.com','Rinu','',NULL,1,'',''),(12,'','','2026-01-29 06:17:30.546678','2026-01-29 06:17:30.546678',12,'user','sanju@gmail.com','sanju','',NULL,1,'',''),(13,'7887789878','Shiva Gas\nAdoor','2026-01-29 09:11:25.721405','2026-02-23 05:40:10.616385',13,'utility','shivagas@gmail.com','shiva','',NULL,0,'','Gas'),(14,'9045544545','WiFi\nAdoor','2026-01-29 09:15:08.527414','2026-02-23 05:40:10.623462',14,'utility','manuwifi@gmail.com','Manu','',NULL,0,'','WiFi'),(15,'9889877889','DTH\nAdoor','2026-01-29 09:20:55.483339','2026-02-23 05:40:10.630362',15,'utility','dasdth@gmail.com','Das','',NULL,0,'','DTH'),(16,'9889885840','Others\nAdoor','2026-01-29 09:27:38.388460','2026-02-23 05:40:10.637280',16,'utility','samothers@gmail.com','Sam','',NULL,0,'','Others');
/*!40000 ALTER TABLE `bills_userprofile` ENABLE KEYS */;
UNLOCK TABLES;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2026-02-24  9:48:20
