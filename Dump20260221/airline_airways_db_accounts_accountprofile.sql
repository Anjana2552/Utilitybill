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
-- Table structure for table `accounts_accountprofile`
--

DROP TABLE IF EXISTS `accounts_accountprofile`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `accounts_accountprofile` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `username` varchar(150) COLLATE utf8mb4_unicode_ci NOT NULL,
  `email` varchar(254) COLLATE utf8mb4_unicode_ci NOT NULL,
  `password` varchar(128) COLLATE utf8mb4_unicode_ci NOT NULL,
  `first_name` varchar(150) COLLATE utf8mb4_unicode_ci NOT NULL,
  `last_name` varchar(150) COLLATE utf8mb4_unicode_ci NOT NULL,
  `phone` varchar(20) COLLATE utf8mb4_unicode_ci NOT NULL,
  `created_at` datetime(6) NOT NULL,
  `role` varchar(20) COLLATE utf8mb4_unicode_ci NOT NULL,
  `company_name` varchar(200) COLLATE utf8mb4_unicode_ci NOT NULL,
  `address` longtext COLLATE utf8mb4_unicode_ci NOT NULL,
  `additional_info` longtext COLLATE utf8mb4_unicode_ci NOT NULL,
  `paypal_email` varchar(254) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `card_expiry` varchar(7) COLLATE utf8mb4_unicode_ci NOT NULL,
  `card_holder_name` varchar(150) COLLATE utf8mb4_unicode_ci NOT NULL,
  `card_last4` varchar(4) COLLATE utf8mb4_unicode_ci NOT NULL,
  `upi_id` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
  `passport_number` varchar(32) COLLATE utf8mb4_unicode_ci NOT NULL,
  `passport_country` varchar(64) COLLATE utf8mb4_unicode_ci NOT NULL,
  `passport_expiry` date DEFAULT NULL,
  `date_of_birth` date DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `username` (`username`),
  UNIQUE KEY `email` (`email`)
) ENGINE=InnoDB AUTO_INCREMENT=8 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `accounts_accountprofile`
--

LOCK TABLES `accounts_accountprofile` WRITE;
/*!40000 ALTER TABLE `accounts_accountprofile` DISABLE KEYS */;
INSERT INTO `accounts_accountprofile` VALUES (1,'anjana@gmail.com','anjana@gmail.com','pbkdf2_sha256$870000$gvUQtwZnTB3fdVabXa5QKY$dSlClL4rdIH8ctJHCNdY2orMAL6ZFTfDxA8lGtRfpAc=','Anjana','','9885588965','2026-01-24 13:44:14.797273','user','','','','anjana@gmail.com','2229','Anjana','3258','','A894572','','2030-07-26','1999-01-10'),(2,'ensate','ensate@gmail.com','pbkdf2_sha256$870000$wE61TCuuNlwwBmMq1EW90e$2jTRe1+KM8Dc6PA+P9LWxSDkLfW1u8rBOi75ar9R7rM=','','','','2026-01-26 16:43:14.240656','admin','','','',NULL,'','','','','','',NULL,NULL),(4,'paru@gmail.com','paru@gmail.com','pbkdf2_sha256$870000$HJ96NefPElvO4Y3o2pg3lK$eYEJVojjfBIF8xB7TEJl451GQlq9iFZqqLkjIdf5MTk=','paru','','','2026-01-27 07:28:24.304045','user','','','',NULL,'','','','','','',NULL,NULL),(7,'staff','staff@gmail.com','pbkdf2_sha256$870000$8VXbuomm0TfIoPUHDz6Uiv$BFJCzvlmmcSjGTmTooRuau0q4L32jTx0bMerSC+TpZY=','','','','2026-02-03 13:00:52.851312','staff','','','',NULL,'','','','','','',NULL,NULL);
/*!40000 ALTER TABLE `accounts_accountprofile` ENABLE KEYS */;
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
