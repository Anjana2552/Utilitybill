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
-- Table structure for table `auth_user`
--

DROP TABLE IF EXISTS `auth_user`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `auth_user` (
  `id` int NOT NULL AUTO_INCREMENT,
  `password` varchar(128) COLLATE utf8mb4_unicode_ci NOT NULL,
  `last_login` datetime(6) DEFAULT NULL,
  `is_superuser` tinyint(1) NOT NULL,
  `username` varchar(150) COLLATE utf8mb4_unicode_ci NOT NULL,
  `first_name` varchar(150) COLLATE utf8mb4_unicode_ci NOT NULL,
  `last_name` varchar(150) COLLATE utf8mb4_unicode_ci NOT NULL,
  `email` varchar(254) COLLATE utf8mb4_unicode_ci NOT NULL,
  `is_staff` tinyint(1) NOT NULL,
  `is_active` tinyint(1) NOT NULL,
  `date_joined` datetime(6) NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `username` (`username`)
) ENGINE=InnoDB AUTO_INCREMENT=18 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `auth_user`
--

LOCK TABLES `auth_user` WRITE;
/*!40000 ALTER TABLE `auth_user` DISABLE KEYS */;
INSERT INTO `auth_user` VALUES (1,'pbkdf2_sha256$870000$S8Z2JCiUKRRfppv77xfSGe$1IjniFt7bPWNl0Z06Y+IfpsrzlNTmYOsSIX2WTobCzI=','2026-02-21 09:29:01.408453',1,'ensate','','','ensate@gmail.com',1,1,'2026-01-07 06:50:14.239000'),(2,'pbkdf2_sha256$870000$d5BpVWrMtZxzDw1VwHlwO0$E1M4GoikcRUeqWgGbDE6V3ANXf+p01zbeB5m9lT3P9Q=','2026-02-23 18:05:41.035725',0,'anjana','anjana','','anjana@gmail.com',0,1,'2026-01-07 07:10:04.557000'),(3,'pbkdf2_sha256$870000$3hrWPnsZmaZNmidV4rziVG$OgKJEFrKg4dZe32DH7wDvsrUF2+EVTZMvfCRjgtS2pM=','2026-02-23 16:34:44.237775',1,'admin','admin','','admin@gmail.com',1,1,'2026-01-07 07:16:41.687000'),(6,'pbkdf2_sha256$870000$kpydXGZiR9Sr8AQ0dAuW34$YjC4TyRZZC1UlUqjcYO1Z9yJo7r5O5skYs8jJfa8VUw=','2026-02-23 16:32:54.747918',0,'amalkseb','','','amalkseb@gmail.com',0,1,'2026-01-17 16:18:03.034977'),(7,'pbkdf2_sha256$870000$YmQggw1Uuq94LTCZcekFvS$fh7oRmSs2WAZNHKBzu5uih5z3M4HV9CiDOF22RQ9mzU=','2026-02-23 16:22:19.284616',0,'achu','achu','','achu@gmail.com',0,1,'2026-01-18 10:28:16.586066'),(8,'pbkdf2_sha256$870000$dXrzLbLhkecMobDmWOnv8w$en6PDpPhMIM76IrcChu14vtvuIk6Auuyl6WhngEC5O4=','2026-02-23 06:00:41.041019',0,'appukwa','','','appukwa@gmail.com',0,1,'2026-01-18 12:35:18.827353'),(10,'pbkdf2_sha256$870000$915HJFB8HLyI3gLNmTurEt$R2H96VD4psfDIPwf1WjPdJfZxW4u8+axWsalIoiUGz0=','2026-02-23 15:36:02.071746',0,'arya','arya','','arya@gmail.com',0,1,'2026-01-29 04:44:54.082405'),(11,'pbkdf2_sha256$870000$mdWwfwmxuI0oN2A4ZFyw3Z$8OCInDHNKXiolQypMVzYdvWThCKswNBPTkOsMiLgi/M=','2026-02-23 15:01:56.424380',0,'rinu','Rinu','','rinu@gmail.com',0,1,'2026-01-29 05:52:54.256611'),(12,'pbkdf2_sha256$870000$pRHQEU846sXLj9MFItyxl4$CaXWhVXhsBG9R+jOCFWFa56YyCMFmRsbgHURDZSVzLA=','2026-02-23 05:50:35.799256',0,'sanju','sanju','','sanju@gmail.com',0,1,'2026-01-29 06:17:30.032386'),(13,'pbkdf2_sha256$870000$IwqyHV9XFfVCNu2MeXOiyB$Mor+QzfHYcHaOA42yrHNeKKxRK14DeFPxSnelYepkbw=','2026-02-23 07:32:23.724789',0,'shivagas','','','shivagas@gmail.com',0,1,'2026-01-29 09:11:24.753177'),(14,'pbkdf2_sha256$870000$Vt2DUiVH2bNHEOZSEgrYxS$Fv3wSSHFjlKtUlPPyyAOPUKmmEG85sX0oVslV5acMsQ=','2026-02-23 07:03:36.464434',0,'manuwifi','','','manuwifi@gmail.com',0,1,'2026-01-29 09:15:07.532614'),(15,'pbkdf2_sha256$870000$S0vD1nN10IP31q4a3ZAqIm$45KPjNAUpZpW+/PnMVhN35wiOzdAlCfM00pKnTt+7Yo=','2026-02-23 06:40:22.028487',0,'dasdth','','','dasdth@gmail.com',0,1,'2026-01-29 09:20:54.392218'),(16,'pbkdf2_sha256$870000$m5F6hrpFiFBnL4Qn5WyrcK$EhLvD8ebdCNTAIvvjIyM37mqBU3QMCkNi9wz5z4JwH8=','2026-02-18 14:23:12.666015',0,'samothers','','','samothers@gmail.com',0,1,'2026-01-29 09:27:37.432761');
/*!40000 ALTER TABLE `auth_user` ENABLE KEYS */;
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
