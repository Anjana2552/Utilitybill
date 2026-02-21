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
-- Table structure for table `auth_permission`
--

DROP TABLE IF EXISTS `auth_permission`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `auth_permission` (
  `id` int NOT NULL AUTO_INCREMENT,
  `name` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `content_type_id` int NOT NULL,
  `codename` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `auth_permission_content_type_id_codename_01ab375a_uniq` (`content_type_id`,`codename`),
  CONSTRAINT `auth_permission_content_type_id_2f476e4b_fk_django_co` FOREIGN KEY (`content_type_id`) REFERENCES `django_content_type` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=93 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `auth_permission`
--

LOCK TABLES `auth_permission` WRITE;
/*!40000 ALTER TABLE `auth_permission` DISABLE KEYS */;
INSERT INTO `auth_permission` VALUES (1,'Can add log entry',1,'add_logentry'),(2,'Can change log entry',1,'change_logentry'),(3,'Can delete log entry',1,'delete_logentry'),(4,'Can view log entry',1,'view_logentry'),(5,'Can add permission',2,'add_permission'),(6,'Can change permission',2,'change_permission'),(7,'Can delete permission',2,'delete_permission'),(8,'Can view permission',2,'view_permission'),(9,'Can add group',3,'add_group'),(10,'Can change group',3,'change_group'),(11,'Can delete group',3,'delete_group'),(12,'Can view group',3,'view_group'),(13,'Can add user',4,'add_user'),(14,'Can change user',4,'change_user'),(15,'Can delete user',4,'delete_user'),(16,'Can view user',4,'view_user'),(17,'Can add content type',5,'add_contenttype'),(18,'Can change content type',5,'change_contenttype'),(19,'Can delete content type',5,'delete_contenttype'),(20,'Can view content type',5,'view_contenttype'),(21,'Can add session',6,'add_session'),(22,'Can change session',6,'change_session'),(23,'Can delete session',6,'delete_session'),(24,'Can view session',6,'view_session'),(25,'Can add category',7,'add_category'),(26,'Can change category',7,'change_category'),(27,'Can delete category',7,'delete_category'),(28,'Can view category',7,'view_category'),(29,'Can add product',8,'add_product'),(30,'Can change product',8,'change_product'),(31,'Can delete product',8,'delete_product'),(32,'Can view product',8,'view_product'),(33,'Can add Wishlist Item',9,'add_wishlistitem'),(34,'Can change Wishlist Item',9,'change_wishlistitem'),(35,'Can delete Wishlist Item',9,'delete_wishlistitem'),(36,'Can view Wishlist Item',9,'view_wishlistitem'),(37,'Can add Registered User',10,'add_registereduser'),(38,'Can change Registered User',10,'change_registereduser'),(39,'Can delete Registered User',10,'delete_registereduser'),(40,'Can view Registered User',10,'view_registereduser'),(41,'Can add Account Profile',11,'add_accountprofile'),(42,'Can change Account Profile',11,'change_accountprofile'),(43,'Can delete Account Profile',11,'delete_accountprofile'),(44,'Can view Account Profile',11,'view_accountprofile'),(45,'Can add product image',12,'add_productimage'),(46,'Can change product image',12,'change_productimage'),(47,'Can delete product image',12,'delete_productimage'),(48,'Can view product image',12,'view_productimage'),(49,'Can add Cart Item',13,'add_cartitem'),(50,'Can change Cart Item',13,'change_cartitem'),(51,'Can delete Cart Item',13,'delete_cartitem'),(52,'Can view Cart Item',13,'view_cartitem'),(53,'Can add Shipping Address',14,'add_shippingaddress'),(54,'Can change Shipping Address',14,'change_shippingaddress'),(55,'Can delete Shipping Address',14,'delete_shippingaddress'),(56,'Can view Shipping Address',14,'view_shippingaddress'),(57,'Can add Payment Method',15,'add_paymentmethod'),(58,'Can change Payment Method',15,'change_paymentmethod'),(59,'Can delete Payment Method',15,'delete_paymentmethod'),(60,'Can view Payment Method',15,'view_paymentmethod'),(61,'Can add order item',16,'add_orderitem'),(62,'Can change order item',16,'change_orderitem'),(63,'Can delete order item',16,'delete_orderitem'),(64,'Can view order item',16,'view_orderitem'),(65,'Can add order',17,'add_order'),(66,'Can change order',17,'change_order'),(67,'Can delete order',17,'delete_order'),(68,'Can view order',17,'view_order'),(69,'Can add flight',18,'add_flight'),(70,'Can change flight',18,'change_flight'),(71,'Can delete flight',18,'delete_flight'),(72,'Can view flight',18,'view_flight'),(73,'Can add my trip',19,'add_mytrip'),(74,'Can change my trip',19,'change_mytrip'),(75,'Can delete my trip',19,'delete_mytrip'),(76,'Can view my trip',19,'view_mytrip'),(77,'Can add food venue',20,'add_foodvenue'),(78,'Can change food venue',20,'change_foodvenue'),(79,'Can delete food venue',20,'delete_foodvenue'),(80,'Can view food venue',20,'view_foodvenue'),(81,'Can add food item',21,'add_fooditem'),(82,'Can change food item',21,'change_fooditem'),(83,'Can delete food item',21,'delete_fooditem'),(84,'Can view food item',21,'view_fooditem'),(85,'Can add contact message',22,'add_contactmessage'),(86,'Can change contact message',22,'change_contactmessage'),(87,'Can delete contact message',22,'delete_contactmessage'),(88,'Can view contact message',22,'view_contactmessage'),(89,'Can add notification',23,'add_notification'),(90,'Can change notification',23,'change_notification'),(91,'Can delete notification',23,'delete_notification'),(92,'Can view notification',23,'view_notification');
/*!40000 ALTER TABLE `auth_permission` ENABLE KEYS */;
UNLOCK TABLES;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2026-02-21  9:52:53
