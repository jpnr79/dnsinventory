/* 
 * Copyright (C) 2025 Javier Samaniego García <jsamaniegog@gmail.com>
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

/* Upgrade migration for GLPI 11 compatibility */

/* Alter configs table to use unsigned integers and utf8mb4 */
ALTER TABLE `glpi_plugin_dnsinventory_configs` 
  MODIFY `id` int(11) UNSIGNED NOT NULL AUTO_INCREMENT,
  CONVERT TO CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci,
  ENGINE=InnoDB;

/* Alter servers table to use unsigned integers and utf8mb4 */
ALTER TABLE `glpi_plugin_dnsinventory_servers`
  MODIFY `id` int(11) UNSIGNED NOT NULL AUTO_INCREMENT,
  MODIFY `entities_id` int(11) UNSIGNED NOT NULL DEFAULT 0,
  CONVERT TO CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci,
  ENGINE=InnoDB;
