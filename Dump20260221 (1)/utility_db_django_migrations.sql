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
-- Table structure for table `django_migrations`
--

DROP TABLE IF EXISTS `django_migrations`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `django_migrations` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `app` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `name` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `applied` datetime(6) NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=37 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `django_migrations`
--

LOCK TABLES `django_migrations` WRITE;
/*!40000 ALTER TABLE `django_migrations` DISABLE KEYS */;
INSERT INTO `django_migrations` VALUES (1,'contenttypes','0001_initial','2026-01-16 05:29:47.531258'),(2,'auth','0001_initial','2026-01-16 05:29:48.695979'),(3,'admin','0001_initial','2026-01-16 05:29:48.967051'),(4,'admin','0002_logentry_remove_auto_add','2026-01-16 05:29:48.978143'),(5,'admin','0003_logentry_add_action_flag_choices','2026-01-16 05:29:48.989920'),(6,'contenttypes','0002_remove_content_type_name','2026-01-16 05:29:49.187359'),(7,'auth','0002_alter_permission_name_max_length','2026-01-16 05:29:49.301125'),(8,'auth','0003_alter_user_email_max_length','2026-01-16 05:29:49.341151'),(9,'auth','0004_alter_user_username_opts','2026-01-16 05:29:49.353302'),(10,'auth','0005_alter_user_last_login_null','2026-01-16 05:29:49.460310'),(11,'auth','0006_require_contenttypes_0002','2026-01-16 05:29:49.465286'),(12,'auth','0007_alter_validators_add_error_messages','2026-01-16 05:29:49.476334'),(13,'auth','0008_alter_user_username_max_length','2026-01-16 05:29:49.604259'),(14,'auth','0009_alter_user_last_name_max_length','2026-01-16 05:29:49.735779'),(15,'auth','0010_alter_group_name_max_length','2026-01-16 05:29:49.767222'),(16,'auth','0011_update_proxy_permissions','2026-01-16 05:29:49.780713'),(17,'auth','0012_alter_user_first_name_max_length','2026-01-16 05:29:49.908307'),(18,'bills','0001_initial','2026-01-16 05:29:50.379570'),(19,'bills','0002_userprofile_role','2026-01-16 05:29:50.490326'),(20,'bills','0003_alter_userprofile_role','2026-01-16 05:29:50.500640'),(21,'bills','0004_remove_utilitybill_user_delete_payment_and_more','2026-01-16 05:29:50.683110'),(22,'bills','0005_userprofile_email_userprofile_full_name','2026-01-16 05:29:50.885673'),(23,'sessions','0001_initial','2026-01-16 05:29:50.964975'),(24,'bills','0006_userutility','2026-01-16 16:50:34.136415'),(25,'bills','0007_generatedbill_utilitybill','2026-01-18 16:24:32.225522'),(26,'authtoken','0001_initial','2026-01-21 16:37:57.315415'),(27,'authtoken','0002_auto_20160226_1747','2026-01-21 16:37:57.360367'),(28,'authtoken','0003_tokenproxy','2026-01-21 16:37:57.371168'),(29,'authtoken','0004_alter_tokenproxy_options','2026-01-21 16:37:57.380282'),(30,'bills','0008_payment','2026-01-22 08:53:22.308583'),(31,'bills','0009_userprofile_otp_fields','2026-01-27 16:16:09.988404'),(32,'bills','0010_chatmessage','2026-01-30 09:00:16.640122'),(33,'bills','0011_rename_bills_chat_user_na_1234_chat_messag_user_na_9bd9ab_idx_and_more','2026-01-30 09:00:16.854661'),(34,'bills','0012_wallet_models','2026-02-18 13:44:13.079461'),(35,'bills','0013_userprofile_house_number','2026-02-20 05:19:57.660384'),(36,'bills','0014_userutility_house_number','2026-02-20 05:22:38.732723');
/*!40000 ALTER TABLE `django_migrations` ENABLE KEYS */;
UNLOCK TABLES;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2026-02-21 10:12:08
