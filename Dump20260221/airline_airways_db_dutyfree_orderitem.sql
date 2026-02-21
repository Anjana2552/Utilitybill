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
-- Table structure for table `dutyfree_orderitem`
--

DROP TABLE IF EXISTS `dutyfree_orderitem`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `dutyfree_orderitem` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `product_name` varchar(200) COLLATE utf8mb4_unicode_ci NOT NULL,
  `unit_price` decimal(10,2) NOT NULL,
  `quantity` int unsigned NOT NULL,
  `order_id` bigint NOT NULL,
  `product_id` bigint DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `dutyfree_orderitem_order_id_70be4593_fk_dutyfree_order_id` (`order_id`),
  KEY `dutyfree_orderitem_product_id_8705ecb2_fk_dutyfree_product_id` (`product_id`),
  CONSTRAINT `dutyfree_orderitem_order_id_70be4593_fk_dutyfree_order_id` FOREIGN KEY (`order_id`) REFERENCES `dutyfree_order` (`id`),
  CONSTRAINT `dutyfree_orderitem_product_id_8705ecb2_fk_dutyfree_product_id` FOREIGN KEY (`product_id`) REFERENCES `dutyfree_product` (`id`),
  CONSTRAINT `dutyfree_orderitem_chk_1` CHECK ((`quantity` >= 0))
) ENGINE=InnoDB AUTO_INCREMENT=11 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `dutyfree_orderitem`
--

LOCK TABLES `dutyfree_orderitem` WRITE;
/*!40000 ALTER TABLE `dutyfree_orderitem` DISABLE KEYS */;
INSERT INTO `dutyfree_orderitem` VALUES (1,'Red Label Blended Scotch Whisky',2250.00,1,1,2),(2,'Burberry Her 50 Ml',8700.00,1,2,12),(3,'Beyond Raw Lit Gummy Worm clinically Dosed Pre-Workout',3410.00,1,3,46),(4,'Red Label Blended Scotch Whisky',2250.00,1,4,2),(5,'GNC Total Lean Bar Vanilla Birthday Cake High-Protein Meal',370.00,1,5,47),(6,'Banana Walnut Cake + Hot Tea (from Cafeccino Express)',570.00,2,6,NULL),(7,'Baggage Service — Domestic (Traveller)',999.00,1,7,NULL),(8,'Age Defender Moisturiser 75ml',7030.00,1,8,15),(9,'Esse Power Bank 3 in1 built-in Cable 10000 Mah, Black',1999.00,1,8,31),(10,'Red Label Blended Scotch Whisky',2250.00,1,9,2);
/*!40000 ALTER TABLE `dutyfree_orderitem` ENABLE KEYS */;
UNLOCK TABLES;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2026-02-21  9:52:48
