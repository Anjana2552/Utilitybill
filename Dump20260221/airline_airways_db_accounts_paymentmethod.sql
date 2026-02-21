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
-- Table structure for table `accounts_paymentmethod`
--

DROP TABLE IF EXISTS `accounts_paymentmethod`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `accounts_paymentmethod` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `type` varchar(20) COLLATE utf8mb4_unicode_ci NOT NULL,
  `paypal_email` varchar(254) COLLATE utf8mb4_unicode_ci NOT NULL,
  `upi_id` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
  `card_holder_name` varchar(150) COLLATE utf8mb4_unicode_ci NOT NULL,
  `card_last4` varchar(4) COLLATE utf8mb4_unicode_ci NOT NULL,
  `card_expiry` varchar(7) COLLATE utf8mb4_unicode_ci NOT NULL,
  `card_brand` varchar(20) COLLATE utf8mb4_unicode_ci NOT NULL,
  `is_default` tinyint(1) NOT NULL,
  `created_at` datetime(6) NOT NULL,
  `updated_at` datetime(6) NOT NULL,
  `user_id` int NOT NULL,
  PRIMARY KEY (`id`),
  KEY `accounts_paymentmethod_user_id_d6721175_fk_auth_user_id` (`user_id`),
  CONSTRAINT `accounts_paymentmethod_user_id_d6721175_fk_auth_user_id` FOREIGN KEY (`user_id`) REFERENCES `auth_user` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `accounts_paymentmethod`
--

LOCK TABLES `accounts_paymentmethod` WRITE;
/*!40000 ALTER TABLE `accounts_paymentmethod` DISABLE KEYS */;
INSERT INTO `accounts_paymentmethod` VALUES (1,'upi','','anjana@oksbi','','','','',0,'2026-02-02 11:48:46.490485','2026-02-02 11:48:46.490485',2),(2,'card','','','Anjana','7895','2229','Card',0,'2026-02-02 11:49:26.615816','2026-02-02 11:49:26.615816',2),(3,'paypal','anjana@gmail.com','','','','','',0,'2026-02-02 11:49:37.955522','2026-02-02 11:49:37.955522',2);
/*!40000 ALTER TABLE `accounts_paymentmethod` ENABLE KEYS */;
UNLOCK TABLES;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2026-02-21  9:52:49
