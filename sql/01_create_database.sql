-- ==============================================================================
-- MotoPulse 360: Intelligent Sales, Inventory & Profitability Analytics Platform
-- Script 01: Database Creation & Environment Configuration
-- Target Database: MySQL 8.x Community Server
-- ==============================================================================
-- DATASET DISCLOSURE:
-- This database is populated from Microsoft AdventureWorksDW, a synthetic sample
-- database modeling a fictional bicycle manufacturing, retail, and commercial
-- wholesale enterprise. It does NOT represent real-world motorcycle data.
-- ==============================================================================

-- 1. Create Database with full Unicode support (utf8mb4)
CREATE DATABASE IF NOT EXISTS motopulse360
    CHARACTER SET utf8mb4
    COLLATE utf8mb4_unicode_ci;

-- 2. Switch to the newly created database context
USE motopulse360;

-- 3. Set Session Execution Parameters for Strict Data Integrity
SET NAMES utf8mb4;
SET sql_mode = 'STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION';
SET foreign_key_checks = 1;

-- Verification query
SELECT 
    SCHEMA_NAME AS database_name,
    DEFAULT_CHARACTER_SET_NAME AS character_set,
    DEFAULT_COLLATION_NAME AS collation_name
FROM information_schema.SCHEMATA
WHERE SCHEMA_NAME = 'motopulse360';
