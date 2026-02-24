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
-- Table structure for table `notification`
--

DROP TABLE IF EXISTS `notification`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `notification` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `notification_type` varchar(50) COLLATE utf8mb4_unicode_ci NOT NULL,
  `title` varchar(200) COLLATE utf8mb4_unicode_ci NOT NULL,
  `message` longtext COLLATE utf8mb4_unicode_ci NOT NULL,
  `utility_type` varchar(50) COLLATE utf8mb4_unicode_ci NOT NULL,
  `bill_id` varchar(64) COLLATE utf8mb4_unicode_ci NOT NULL,
  `due_date` date DEFAULT NULL,
  `read` tinyint(1) NOT NULL,
  `created_at` datetime(6) NOT NULL,
  `user_id` int NOT NULL,
  PRIMARY KEY (`id`),
  KEY `notificatio_user_id_366c29_idx` (`user_id`,`created_at` DESC),
  KEY `notificatio_user_id_d59197_idx` (`user_id`,`read`),
  KEY `notificatio_utility_2adc3f_idx` (`utility_type`),
  CONSTRAINT `notification_user_id_1002fc38_fk_auth_user_id` FOREIGN KEY (`user_id`) REFERENCES `auth_user` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=14 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `notification`
--

LOCK TABLES `notification` WRITE;
/*!40000 ALTER TABLE `notification` DISABLE KEYS */;
INSERT INTO `notification` VALUES (1,'payment_initiated','Payment Initiated','Payment of ₹800 for Electricity bill has been initiated. Bill ID: KSEB-20260220183702','Electricity','KSEB-20260220183702',NULL,1,'2026-02-22 13:03:36.065379',7),(2,'payment_approved','Payment Approved','Your payment of ₹800.00 for Electricity bill has been approved. Thank you!','Electricity','KSEB-20260220183702',NULL,1,'2026-02-22 13:56:22.906446',7),(3,'payment_initiated','Payment Initiated','Payment of ₹1600 for Electricity bill has been initiated. Bill ID: KSEB-20260220184521','Electricity','KSEB-20260220184521',NULL,1,'2026-02-22 17:46:05.399175',2),(4,'bill_generated','Test: New Electricity Bill','This is a test notification for bill generation. Amount: ₹500','Electricity','TEST-001',NULL,1,'2026-02-23 05:40:46.479958',2),(5,'payment_initiated','Test: Payment Initiated','User anjana initiated payment for Electricity bill TEST-001. Amount: ₹500','Electricity','TEST-001',NULL,0,'2026-02-23 05:40:46.498700',6),(6,'bill_generated','New Electricity Bill Generated','A new bill for Electricity (KSEB) has been generated. Amount: ₹750. Due date: March 02, 2026','Electricity','TEST-KSEB-20260223112231','2026-03-02',0,'2026-02-23 05:52:31.092579',2),(7,'bill_generated','New Water Bill Generated','A new bill (ID: TEST-WATER-20260223000000) for Water has been generated. Amount: ₹150.5. Please check your bills section.','Water','TEST-WATER-20260223000000',NULL,1,'2026-02-23 07:23:28.515094',11),(8,'bill_generated','New Gas Bill Generated','A new bill (ID: LPG-20260223125818) for Gas has been generated. Amount: ₹832.00. Please check your bills section.','Gas','LPG-20260223125818',NULL,1,'2026-02-23 07:28:47.237194',10),(9,'bill_generated','New Gas Bill Generated','A new bill (ID: LPG-20260223125847) for Gas has been generated. Amount: ₹800.00. Please check your bills section.','Gas','LPG-20260223125847',NULL,1,'2026-02-23 07:29:11.617495',7),(10,'payment_initiated','Payment Initiated','Payment of ₹800 for Gas bill has been initiated. Bill ID: LPG-20260223125847','Gas','LPG-20260223125847',NULL,1,'2026-02-23 07:30:57.010981',7),(11,'payment_initiated','Payment Initiated','User achu initiated payment for Gas bill LPG-20260223125847 (₹800).','Gas','LPG-20260223125847',NULL,1,'2026-02-23 07:30:57.021865',13),(12,'payment_rejected','Payment Rejected','Your payment of ₹800.00 for Gas bill has been rejected. Amount refunded to your wallet.','Gas','LPG-20260223125847',NULL,1,'2026-02-23 07:32:04.914661',7),(13,'payment_rejected','Payment Rejected','User achu payment rejected for Gas bill LPG-20260223125847 (₹800.00).','Gas','LPG-20260223125847',NULL,1,'2026-02-23 07:32:04.925485',13);
/*!40000 ALTER TABLE `notification` ENABLE KEYS */;
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
