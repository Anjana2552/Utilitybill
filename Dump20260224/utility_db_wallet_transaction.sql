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
-- Table structure for table `wallet_transaction`
--

DROP TABLE IF EXISTS `wallet_transaction`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `wallet_transaction` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `amount` decimal(12,2) NOT NULL,
  `type` varchar(10) COLLATE utf8mb4_unicode_ci NOT NULL,
  `reason` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `created_at` datetime(6) NOT NULL,
  `payment_id` bigint DEFAULT NULL,
  `wallet_id` bigint NOT NULL,
  PRIMARY KEY (`id`),
  KEY `wallet_transaction_payment_id_b4ba988d_fk_payment_id` (`payment_id`),
  KEY `wallet_transaction_wallet_id_a0ff1b17_fk_wallet_id` (`wallet_id`),
  CONSTRAINT `wallet_transaction_payment_id_b4ba988d_fk_payment_id` FOREIGN KEY (`payment_id`) REFERENCES `payment` (`id`),
  CONSTRAINT `wallet_transaction_wallet_id_a0ff1b17_fk_wallet_id` FOREIGN KEY (`wallet_id`) REFERENCES `wallet` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=15 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `wallet_transaction`
--

LOCK TABLES `wallet_transaction` WRITE;
/*!40000 ALTER TABLE `wallet_transaction` DISABLE KEYS */;
INSERT INTO `wallet_transaction` VALUES (1,799.00,'credit','Refund for rejected payment KSEB-20260129143403','2026-02-18 16:00:55.744121',8,2),(2,100.00,'credit','Reward: big reduction (>=200 vs previous)','2026-02-23 05:23:50.829014',11,2),(3,800.00,'credit','Refund for rejected payment LPG-20260223125847','2026-02-23 07:32:04.907884',12,1),(4,100.00,'credit','Added funds via Credit Card','2026-02-23 08:23:45.468816',NULL,2),(5,1.00,'credit','Added funds via Credit Card','2026-02-23 08:27:54.080702',NULL,2),(6,500.00,'credit','Added funds via UPI','2026-02-23 15:02:57.701925',NULL,5),(7,5.00,'credit','Added funds via UPI','2026-02-23 15:19:56.866820',NULL,5),(8,500.00,'credit','Added funds via Bank Transfer','2026-02-23 15:37:06.206103',NULL,3),(9,5.00,'credit','Added funds via Bank Transfer','2026-02-23 15:42:40.009919',NULL,3),(10,1.00,'credit','Added funds via Credit Card','2026-02-23 15:46:10.933545',NULL,1),(11,1.00,'credit','Added funds via Credit Card','2026-02-23 15:47:10.831313',NULL,1),(12,1.00,'credit','Added funds via Credit Card','2026-02-23 15:53:27.919857',NULL,1),(13,1.00,'credit','Added funds via Credit Card','2026-02-23 15:58:38.079018',NULL,1),(14,0.10,'credit','Cashback on wallet top-up','2026-02-23 15:58:38.084810',NULL,1);
/*!40000 ALTER TABLE `wallet_transaction` ENABLE KEYS */;
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
