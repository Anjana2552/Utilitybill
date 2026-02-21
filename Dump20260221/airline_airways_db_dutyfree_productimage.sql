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
-- Table structure for table `dutyfree_productimage`
--

DROP TABLE IF EXISTS `dutyfree_productimage`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `dutyfree_productimage` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `image` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
  `alt_text` varchar(200) COLLATE utf8mb4_unicode_ci NOT NULL,
  `order` int unsigned NOT NULL,
  `product_id` bigint NOT NULL,
  PRIMARY KEY (`id`),
  KEY `dutyfree_productimage_product_id_38a20c16_fk_dutyfree_product_id` (`product_id`),
  CONSTRAINT `dutyfree_productimage_product_id_38a20c16_fk_dutyfree_product_id` FOREIGN KEY (`product_id`) REFERENCES `dutyfree_product` (`id`),
  CONSTRAINT `dutyfree_productimage_chk_1` CHECK ((`order` >= 0))
) ENGINE=InnoDB AUTO_INCREMENT=82 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `dutyfree_productimage`
--

LOCK TABLES `dutyfree_productimage` WRITE;
/*!40000 ALTER TABLE `dutyfree_productimage` DISABLE KEYS */;
INSERT INTO `dutyfree_productimage` VALUES (1,'product_images/7142---Whisky-Johnnie-Walker-Black-Label-1L.webp','',0,1),(2,'product_images/whisky-johnnie-walker-black-label-1l-3-unidades-1.webp','',0,1),(3,'product_images/Johnnie_Walker_-_Купити_віскі_Джонні_Вокер_у_Києві_Україні___Ціна_Відгуки_UfBwXoN.jpg','',0,1),(4,'product_images/johnnie-walker-red-label-blended-scotch-whisky-6384cc544752d.png','',0,2),(5,'product_images/JohnnieWalkerRedLabelBlendedScotchWhiskyLimitedEditionTin.webp','',0,2),(6,'product_images/Untitleddesign-2021-05-02T012533.111_2048x2048.webp','',0,2),(7,'product_images/6175110-001.jpg','',0,3),(8,'product_images/OIP_1.jpg','',0,3),(9,'product_images/OIP.jpg','',0,3),(10,'product_images/OIP_3.jpg','',0,4),(11,'product_images/dermalogica-moisturisers-super-rich-repair-50-ml-30249464430759.webp','',0,4),(12,'product_images/super-rich-repair_1.7oz_main-with-benefits.webp','',0,4),(13,'product_images/OIP_2.jpg','',0,4),(14,'product_images/OIP_4.jpg','',0,5),(15,'product_images/img.webp','',0,5),(16,'product_images/m.webp','',0,5),(17,'product_images/910h6K787-L._SL1500_.jpg','',0,6),(18,'product_images/file.jpg','',0,6),(19,'product_images/l-intro-1663094453.jpg','',0,6),(20,'product_images/95236502c6b6ee780f67ccb8a3c591ac.jpeg','',0,7),(21,'product_images/davidoff-cool-water-oceanic-edition-woman-eau-de-toilette-17_jheite4.jpg','',0,8),(22,'product_images/DAVIDOFF-COOL-WATER-FOR-WOMEN-EAU-DE-TOILETTE-100ML.jpg','',0,8),(23,'product_images/ba2.jpg','',0,9),(24,'product_images/ba3.webp','',0,9),(25,'product_images/ba4.jpg','',0,9),(26,'product_images/bo_16-2.jpg','',0,10),(27,'product_images/bo16_3.webp','',0,10),(28,'product_images/bo16-1.jpg','',0,10),(29,'product_images/1012359508-Chivas-Regal-18-YO-Blended-Scotch-Whisky-40-vol-0-70l-48614.jpg','',0,11),(30,'product_images/OIP_5.jpg','',0,11),(31,'product_images/chivas-regal-18-year-old-gold-signature-scotch-whisky-700ml-and-gift-box.webp','',0,11),(32,'product_images/b.png','',0,12),(33,'product_images/gg.webp','',0,12),(34,'product_images/ab2.webp','',0,13),(35,'product_images/ab3.png','',0,13),(36,'product_images/j2.webp','',0,14),(37,'product_images/j3.jpg','',0,14),(38,'product_images/k2.webp','',0,15),(39,'product_images/k3.jpg','',0,15),(40,'product_images/mm1.jpg','',0,16),(41,'product_images/51ui0lbrFML._SL1500_.jpg','',0,16),(42,'product_images/0d0378930c13499bb384771b41ed6a82.webp','',0,17),(43,'product_images/bobbi-brown-crushed-oil-infused-gloss-duo-gift-set-for-lips___240923.webp','',0,17),(44,'product_images/gucci-cushion-de-beaute-foundation-spf-2-02.jpg','',0,18),(45,'product_images/l.webp','',0,18),(46,'product_images/jj.jpg','',0,19),(47,'product_images/genifique-bundle-24.jpg','',0,19),(48,'product_images/genifique-ultimate-serum-alt6-V3.webp','',0,19),(49,'product_images/mac-in-extreme-dimension-waterproof-lash-mascara-dimensional-black-1339g0_VKN1Mhg.jpg','',0,20),(50,'product_images/2476803detailImage01.jpg','',0,20),(51,'product_images/OIP_6.jpg','',0,21),(52,'product_images/hh.webp','',0,22),(53,'product_images/crystal-noir-parfum___250401.webp','',0,22),(54,'product_images/hhdf.png','',0,23),(55,'product_images/prod_img-1380142_orig.png','',0,23),(56,'product_images/qqq.jpg','',0,24),(57,'product_images/milk-chocolate-honeycomb-crisp-butlers-chocolate-full.png','',0,24),(58,'product_images/7610400089715_1_1.jpg','',0,25),(59,'product_images/hhhh.jpg','',0,26),(60,'product_images/kkkkkkkkkkkkkk.jpg','',0,26),(61,'product_images/search.jpg','',0,27),(62,'product_images/1502124-01.webp','',0,28),(63,'product_images/1502124-02.webp','',0,28),(64,'product_images/GA-B010-3A.png','',0,29),(65,'product_images/GA-B010-3A.jpg','',0,29),(66,'product_images/jjjj.jpg','',0,30),(67,'product_images/hhhhhhhhhhhhhh.jpg','',0,30),(68,'product_images/gggggggggggg.jpg','',0,30),(69,'product_images/2_08F04174.jpeg','',0,31),(70,'product_images/3_08F04174.jpeg','',0,31),(71,'product_images/4_08F04174.jpeg','',0,31),(72,'product_images/08H01481_1.png','',0,32),(73,'product_images/08H014811.png','',0,32),(74,'product_images/08H014813.png','',0,32),(75,'product_images/08H014814.png','',0,32),(76,'product_images/1_08H01568.jpg','',0,33),(77,'product_images/08H01474_1.png','',0,34),(78,'product_images/08H014741.png','',0,34),(79,'product_images/2.jpg','',0,48),(80,'product_images/3.jpg','',0,48),(81,'product_images/4.jpg','',0,48);
/*!40000 ALTER TABLE `dutyfree_productimage` ENABLE KEYS */;
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
