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
) ENGINE=InnoDB AUTO_INCREMENT=45 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `django_migrations`
--

LOCK TABLES `django_migrations` WRITE;
/*!40000 ALTER TABLE `django_migrations` DISABLE KEYS */;
INSERT INTO `django_migrations` VALUES (1,'contenttypes','0001_initial','2026-01-23 10:58:12.409123'),(2,'auth','0001_initial','2026-01-23 10:58:13.491766'),(3,'admin','0001_initial','2026-01-23 10:58:13.781402'),(4,'admin','0002_logentry_remove_auto_add','2026-01-23 10:58:13.815613'),(5,'admin','0003_logentry_add_action_flag_choices','2026-01-23 10:58:13.829399'),(6,'contenttypes','0002_remove_content_type_name','2026-01-23 10:58:14.032068'),(7,'auth','0002_alter_permission_name_max_length','2026-01-23 10:58:14.149685'),(8,'auth','0003_alter_user_email_max_length','2026-01-23 10:58:14.187003'),(9,'auth','0004_alter_user_username_opts','2026-01-23 10:58:14.197901'),(10,'auth','0005_alter_user_last_login_null','2026-01-23 10:58:14.308944'),(11,'auth','0006_require_contenttypes_0002','2026-01-23 10:58:14.313581'),(12,'auth','0007_alter_validators_add_error_messages','2026-01-23 10:58:14.327521'),(13,'auth','0008_alter_user_username_max_length','2026-01-23 10:58:14.452952'),(14,'auth','0009_alter_user_last_name_max_length','2026-01-23 10:58:14.575798'),(15,'auth','0010_alter_group_name_max_length','2026-01-23 10:58:14.609357'),(16,'auth','0011_update_proxy_permissions','2026-01-23 10:58:14.620689'),(17,'auth','0012_alter_user_first_name_max_length','2026-01-23 10:58:14.739691'),(18,'dutyfree','0001_initial','2026-01-23 10:58:14.917947'),(19,'sessions','0001_initial','2026-01-23 10:58:14.987127'),(20,'dutyfree','0002_product_badge_text_product_brand_product_old_price','2026-01-23 12:01:53.209671'),(21,'dutyfree','0003_wishlistitem','2026-01-23 17:51:58.360994'),(22,'core','0001_initial','2026-01-23 18:01:38.223133'),(23,'accounts','0001_initial','2026-01-24 13:32:12.393030'),(24,'accounts','0002_accountprofile_role','2026-01-26 15:59:17.696807'),(25,'dutyfree','0004_productimage','2026-02-02 06:46:15.598248'),(26,'dutyfree','0005_cartitem','2026-02-02 07:20:16.993038'),(27,'accounts','0003_accountprofile_shipping_fields','2026-02-02 09:07:38.229114'),(28,'accounts','0004_shippingaddress','2026-02-02 09:42:15.079805'),(29,'accounts','0005_accountprofile_paypal_email','2026-02-02 10:42:27.887208'),(30,'accounts','0006_accountprofile_card_expiry_and_more','2026-02-02 10:57:22.281807'),(31,'accounts','0007_paymentmethod','2026-02-02 11:46:02.387126'),(32,'dutyfree','0006_order_orderitem','2026-02-02 15:27:27.889332'),(33,'dutyfree','0007_alter_order_status','2026-02-02 15:52:33.533408'),(34,'accounts','0008_accountprofile_passport_details','2026-02-04 06:37:50.408297'),(35,'core','0002_flight','2026-02-04 10:15:51.739726'),(36,'core','0003_flight_repeat_active','2026-02-04 10:15:52.039624'),(37,'core','0004_flight_status','2026-02-04 10:30:26.557720'),(38,'core','0005_flight_delay_hours','2026-02-04 10:38:56.447933'),(39,'accounts','0009_mytrip','2026-02-06 11:02:58.214874'),(40,'core','0006_foodvenue','2026-02-10 08:10:51.951277'),(41,'core','0007_fooditem','2026-02-10 08:45:37.362618'),(42,'core','0008_flight_flight_number','2026-02-17 06:14:02.664408'),(43,'core','0009_contactmessage','2026-02-17 09:32:51.743025'),(44,'dutyfree','0008_notification','2026-02-17 10:03:38.849183');
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

-- Dump completed on 2026-02-21  9:52:51
