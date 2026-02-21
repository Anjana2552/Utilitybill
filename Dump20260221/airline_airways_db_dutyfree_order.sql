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
-- Table structure for table `dutyfree_order`
--

DROP TABLE IF EXISTS `dutyfree_order`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `dutyfree_order` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `created_at` datetime(6) NOT NULL,
  `delivery_method` varchar(10) COLLATE utf8mb4_unicode_ci NOT NULL,
  `payment_method` varchar(10) COLLATE utf8mb4_unicode_ci NOT NULL,
  `transaction_id` varchar(32) COLLATE utf8mb4_unicode_ci NOT NULL,
  `address_snapshot` longtext COLLATE utf8mb4_unicode_ci NOT NULL,
  `pickup_info` json DEFAULT NULL,
  `subtotal` decimal(10,2) NOT NULL,
  `taxes` decimal(10,2) NOT NULL,
  `total` decimal(10,2) NOT NULL,
  `status` varchar(20) COLLATE utf8mb4_unicode_ci NOT NULL,
  `user_id` int NOT NULL,
  PRIMARY KEY (`id`),
  KEY `dutyfree_order_user_id_de50078b_fk_auth_user_id` (`user_id`),
  CONSTRAINT `dutyfree_order_user_id_de50078b_fk_auth_user_id` FOREIGN KEY (`user_id`) REFERENCES `auth_user` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=10 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `dutyfree_order`
--

LOCK TABLES `dutyfree_order` WRITE;
/*!40000 ALTER TABLE `dutyfree_order` DISABLE KEYS */;
INSERT INTO `dutyfree_order` VALUES (1,'2026-02-02 15:29:51.781186','online','upi','TXZYG7OO5S','anjana | ensate | Kollam | 690561 | 9885588965',NULL,2250.00,0.00,2250.00,'delivered',2),(2,'2026-02-03 06:26:47.254030','online','paypal','TXZM8HEN9U','anjana | Adoor kerala | 690555 | 9885588965',NULL,8700.00,0.00,8700.00,'delivered',2),(3,'2026-02-03 07:08:49.338371','online','card','TXXGUS8EXP','anjana | Adoor kerala | 690555 | 9885588965',NULL,3410.00,0.00,3410.00,'delivered',2),(4,'2026-02-03 09:58:45.120538','offline','upi','TX72KCZML0','','{\"primary\": {\"dob\": \"1999-01-10\", \"expiry\": \"2030-06-12\", \"number\": \"789546\", \"full_name\": \"Anjana\", \"nationality\": \"Indian\"}, \"is_transit\": \"no\", \"passengers\": [], \"flight_number\": \"AI-789\", \"flight_source\": \"India\", \"pickup_details\": {\"type\": \"arrival\", \"terminal\": \"T2\"}, \"flight_datetime\": \"2026-02-05T12:29\", \"flight_location\": \"Thiruvananthapuram\", \"collected_status\": \"not_collected\"}',2250.00,0.00,2250.00,'pending',2),(5,'2026-02-04 06:19:38.787483','offline','paypal','TXUVDS1GEK','','{\"primary\": {\"dob\": \"1999-01-10\", \"expiry\": \"2030-06-13\", \"number\": \"789546\", \"full_name\": \"Anjana\", \"nationality\": \"Indian\"}, \"is_transit\": \"no\", \"passengers\": [], \"flight_number\": \"AI-548\", \"flight_source\": \"United Kingdom\", \"pickup_details\": {\"type\": \"departure\", \"terminal\": \"T2\"}, \"flight_datetime\": \"2026-02-04T13:51\", \"flight_location\": \"uk\", \"collected_status\": \"not_collected\"}',370.00,0.00,370.00,'ordered',2),(6,'2026-02-15 08:32:11.742342','online','paypal','FNBNK3PZ3JI3H','',NULL,1140.00,205.20,1345.20,'in_transit',2),(7,'2026-02-17 08:25:24.815695','online','upi','BAGYWRY7XDMCX','','{\"flow\": \"dom\", \"service\": \"baggage\", \"flow_label\": \"Domestic (Traveller)\"}',999.00,0.00,999.00,'in_transit',2),(8,'2026-02-17 10:07:26.632367','offline','paypal','TXZ4W2T9NX','','{\"primary\": {\"dob\": \"1999-01-10\", \"expiry\": \"2030-07-26\", \"number\": \"A894572\", \"full_name\": \"Anjana\", \"nationality\": \"Indian\"}, \"is_transit\": \"no\", \"passengers\": [], \"flight_number\": \"AI-789\", \"flight_source\": \"Afghanistan\", \"pickup_details\": {\"type\": \"arrival\", \"terminal\": \"T1\"}, \"flight_datetime\": \"2026-02-17T15:37\", \"flight_location\": \"uk\"}',9029.00,0.00,9029.00,'ordered',2),(9,'2026-02-17 10:09:36.912064','online','paypal','TXI5X8Q9H9','anjana | ensate | Kollam | 690561 | 9885588965',NULL,2250.00,0.00,2250.00,'ordered',2);
/*!40000 ALTER TABLE `dutyfree_order` ENABLE KEYS */;
UNLOCK TABLES;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2026-02-21  9:52:50
