CREATE DATABASE IF NOT EXISTS `grabber_gateway`;
CREATE DATABASE IF NOT EXISTS `grabber_auth`;
CREATE DATABASE IF NOT EXISTS `grabber_robot`;
CREATE DATABASE IF NOT EXISTS `grabber_telemetry`;
CREATE DATABASE IF NOT EXISTS `grabber_ai`;

GRANT ALL PRIVILEGES ON `grabber_gateway`.* TO 'thathsara'@'%';
GRANT ALL PRIVILEGES ON `grabber_auth`.* TO 'thathsara'@'%';
GRANT ALL PRIVILEGES ON `grabber_robot`.* TO 'thathsara'@'%';
GRANT ALL PRIVILEGES ON `grabber_telemetry`.* TO 'thathsara'@'%';
GRANT ALL PRIVILEGES ON `grabber_ai`.* TO 'thathsara'@'%';
FLUSH PRIVILEGES;
