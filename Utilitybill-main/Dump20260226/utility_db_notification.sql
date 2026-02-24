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
) ENGINE=InnoDB AUTO_INCREMENT=39 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `notification`
--

LOCK TABLES `notification` WRITE;
/*!40000 ALTER TABLE `notification` DISABLE KEYS */;
INSERT INTO `notification` VALUES (1,'payment_initiated','Payment Initiated','Payment of ₹800 for Electricity bill has been initiated. Bill ID: KSEB-20260220183702','Electricity','KSEB-20260220183702',NULL,1,'2026-02-22 13:03:36.065379',7),(2,'payment_approved','Payment Approved','Your payment of ₹800.00 for Electricity bill has been approved. Thank you!','Electricity','KSEB-20260220183702',NULL,1,'2026-02-22 13:56:22.906446',7),(3,'payment_initiated','Payment Initiated','Payment of ₹1600 for Electricity bill has been initiated. Bill ID: KSEB-20260220184521','Electricity','KSEB-20260220184521',NULL,1,'2026-02-22 17:46:05.399175',2),(4,'bill_generated','Test: New Electricity Bill','This is a test notification for bill generation. Amount: ₹500','Electricity','TEST-001',NULL,1,'2026-02-23 05:40:46.479958',2),(5,'payment_initiated','Test: Payment Initiated','User anjana initiated payment for Electricity bill TEST-001. Amount: ₹500','Electricity','TEST-001',NULL,1,'2026-02-23 05:40:46.498700',6),(6,'bill_generated','New Electricity Bill Generated','A new bill for Electricity (KSEB) has been generated. Amount: ₹750. Due date: March 02, 2026','Electricity','TEST-KSEB-20260223112231','2026-03-02',1,'2026-02-23 05:52:31.092579',2),(7,'bill_generated','New Water Bill Generated','A new bill (ID: TEST-WATER-20260223000000) for Water has been generated. Amount: ₹150.5. Please check your bills section.','Water','TEST-WATER-20260223000000',NULL,1,'2026-02-23 07:23:28.515094',11),(8,'bill_generated','New Gas Bill Generated','A new bill (ID: LPG-20260223125818) for Gas has been generated. Amount: ₹832.00. Please check your bills section.','Gas','LPG-20260223125818',NULL,1,'2026-02-23 07:28:47.237194',10),(9,'bill_generated','New Gas Bill Generated','A new bill (ID: LPG-20260223125847) for Gas has been generated. Amount: ₹800.00. Please check your bills section.','Gas','LPG-20260223125847',NULL,1,'2026-02-23 07:29:11.617495',7),(10,'payment_initiated','Payment Initiated','Payment of ₹800 for Gas bill has been initiated. Bill ID: LPG-20260223125847','Gas','LPG-20260223125847',NULL,1,'2026-02-23 07:30:57.010981',7),(11,'payment_initiated','Payment Initiated','User achu initiated payment for Gas bill LPG-20260223125847 (₹800).','Gas','LPG-20260223125847',NULL,1,'2026-02-23 07:30:57.021865',13),(12,'payment_rejected','Payment Rejected','Your payment of ₹800.00 for Gas bill has been rejected. Amount refunded to your wallet.','Gas','LPG-20260223125847',NULL,1,'2026-02-23 07:32:04.914661',7),(13,'payment_rejected','Payment Rejected','User achu payment rejected for Gas bill LPG-20260223125847 (₹800.00).','Gas','LPG-20260223125847',NULL,1,'2026-02-23 07:32:04.925485',13),(14,'payment_initiated','Payment Initiated','Payment of ₹960 for Electricity bill has been initiated. Bill ID: KSEB-20260223111932','Electricity','KSEB-20260223111932',NULL,0,'2026-02-24 06:54:40.721694',10),(15,'payment_initiated','Payment Initiated','User arya initiated payment for Electricity bill KSEB-20260223111932 (₹960).','Electricity','KSEB-20260223111932',NULL,0,'2026-02-24 06:54:40.732031',6),(16,'payment_approved','Payment Approved','Your payment of ₹960.00 for Electricity bill has been approved. Thank you!','Electricity','KSEB-20260223111932',NULL,0,'2026-02-24 06:56:26.743734',10),(17,'payment_approved','Payment Approved','User arya payment approved for Electricity bill KSEB-20260223111932 (₹960.00).','Electricity','KSEB-20260223111932',NULL,0,'2026-02-24 06:56:26.755838',6),(18,'budget_alert','⚠️ Monthly Budget Exceeded','Your monthly utility spending of ₹3500.00 has exceeded your budget limit of ₹3000.00 by ₹500.00 (117% of budget).','budget','',NULL,0,'2026-02-24 07:13:42.162453',2),(23,'urgent_alert','URGENT: Scheduled Maintenance','Power maintenance scheduled for February 25, 2026 from 9:00 AM to 12:00 PM. Please plan accordingly.','Electricity','',NULL,1,'2026-02-24 07:33:48.536091',2),(24,'urgent_alert','URGENT: Scheduled Maintenance','Power maintenance scheduled for February 25, 2026 from 9:00 AM to 12:00 PM. Please plan accordingly.','Electricity','',NULL,0,'2026-02-24 07:33:48.543264',7),(25,'urgent_alert','URGENT: Scheduled Maintenance','Power maintenance scheduled for February 25, 2026 from 9:00 AM to 12:00 PM. Please plan accordingly.','Electricity','',NULL,0,'2026-02-24 07:33:48.548390',12),(26,'urgent_alert','URGENT: Scheduled Maintenance','Power maintenance scheduled for February 25, 2026 from 9:00 AM to 12:00 PM. Please plan accordingly.','Electricity','',NULL,0,'2026-02-24 07:33:48.554946',10),(27,'alert','IMPORTANT: WiFi Speed','There is chance that WIFI speed will decrease at times today.','WiFi','',NULL,1,'2026-02-24 07:48:10.976143',2),(28,'alert','IMPORTANT: WiFi Speed','There is chance that WIFI speed will decrease at times today.','WiFi','',NULL,0,'2026-02-24 07:48:10.984644',12),(29,'alert','IMPORTANT: WiFi Speed','There is chance that WIFI speed will decrease at times today.','WiFi','',NULL,0,'2026-02-24 07:48:10.990010',7),(30,'alert','IMPORTANT: WiFi Speed','There is chance that WIFI speed will decrease at times today.','WiFi','',NULL,0,'2026-02-24 07:48:10.996858',11),(31,'alert','INFO: power cut','today there will power cut between 2 pm to 3 pm','Electricity','',NULL,1,'2026-02-24 08:15:11.083638',2),(32,'alert','INFO: power cut','today there will power cut between 2 pm to 3 pm','Electricity','',NULL,0,'2026-02-24 08:15:11.124147',7),(33,'alert','INFO: power cut','today there will power cut between 2 pm to 3 pm','Electricity','',NULL,0,'2026-02-24 08:15:11.133251',12),(34,'alert','INFO: power cut','today there will power cut between 2 pm to 3 pm','Electricity','',NULL,0,'2026-02-24 08:15:11.142779',10),(35,'payment_initiated','Payment Initiated','Payment of ₹808 for Electricity bill has been initiated. Bill ID: KSEB-20260224134213','Electricity','KSEB-20260224134213',NULL,1,'2026-02-24 08:17:16.982579',18),(36,'payment_initiated','Payment Initiated','User aswinms initiated payment for Electricity bill KSEB-20260224134213 (₹808).','Electricity','KSEB-20260224134213',NULL,0,'2026-02-24 08:17:16.994514',6),(37,'payment_approved','Payment Approved','Your payment of ₹808.00 for Electricity bill has been approved. Thank you!','Electricity','KSEB-20260224134213',NULL,0,'2026-02-24 08:24:20.594891',18),(38,'payment_approved','Payment Approved','User aswinms payment approved for Electricity bill KSEB-20260224134213 (₹808.00).','Electricity','KSEB-20260224134213',NULL,0,'2026-02-24 08:24:20.607794',6);
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

-- Dump completed on 2026-02-24 15:11:04
