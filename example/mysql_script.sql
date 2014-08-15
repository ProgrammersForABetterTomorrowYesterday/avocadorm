-- Creates the database.
CREATE DATABASE `avocadorm_example`;

-- Creates a guest user with only SELECT privilege.
CREATE USER 'avocadorm_guest'@'localhost' IDENTIFIED BY 'pwd';
GRANT SELECT ON `avocadorm_example`.* TO 'avocadorm_guest'@'localhost';

-- Creates an admin user with privileges related to the ORM.
CREATE USER 'avocadorm_admin'@'localhost' IDENTIFIED BY 'password';
GRANT SELECT, INSERT, UPDATE, DELETE ON `avocadorm_example`.* TO 'avocadorm_admin'@'localhost';


USE `avocadorm_example`;


-- Creates the necessary tables for the example.

CREATE TABLE `company` (
    `company_id` INT PRIMARY KEY AUTO_INCREMENT,
    `name` NVARCHAR(128) NOT NULL
);

CREATE TABLE `employee_type` (
    `employee_type_id` INT PRIMARY KEY AUTO_INCREMENT,
    `name` NVARCHAR(64) NOT NULL
);

CREATE TABLE `employee` (
    `employee_id` INT PRIMARY KEY AUTO_INCREMENT,
    `name` NVARCHAR(128) NOT NULL,
    `address` NVARCHAR(256),
    `email` NVARCHAR(128),
    `company_id` INT ,
    `employee_type_id` INT,
    CONSTRAINT `fk_employee_company` FOREIGN KEY `fk_employee_company` (`company_id`) REFERENCES `company` (`company_id`),
    CONSTRAINT `fk_employee_employee_type` FOREIGN KEY `fk_employee_employee_type` (`employee_type_id`) REFERENCES `employee_type` (`employee_type_id`)
);


-- Creates some data for the example.

INSERT INTO `company` (`name`) VALUES
    ('Easy Stuff inc.'),
    ('Super Hospital'),
    ('Brown, Martin & Miller');

INSERT INTO `employee_type` (`name`) VALUES
    ('CEO'),
    ('Manager'),
    ('Secretary'),
    ('Janitor'),
    ('Lawyer'),
    ('Consultant'),
    ('Supervisor'),
    ('Doctor'),
    ('Nurse');

INSERT INTO `employee` (`name`, `address`, `email`, `company_id`, `employee_type_id`) VALUES
    ('Sandra Allen', '7297 Indian Pine Pike, Luck, Alberta, T7S 5H6, CA', 'sallen@easystuffinc.com', 1, 7),
    ('Christina Johnson', '6554 Rustic Lagoon Inlet, Tomahawk, New Brunswick, E0Z 9M6, CA', 'cjohnson@easystuffinc.com', 1, 4),
    ('Virginia Roberts', '4602 Crystal Glade, Chukut Kuk, Louisiana, 71075-4625, US', 'virgo_gurl@yahooo.com', 2, 9),
    ('Deborah Lopez', '6426 Merry Gate Landing, Bracken, Florida, 34392-6374, US', 'dlopez@easystuffinc.com', 1, 6),
    ('Sean Brown', '3756 Burning Ledge, Sheshebee, Britsh Columbia, V9X 5R6, CA', 'brown@brownmartinmiller.com', 3, 5),
    ('Larry Patterson', '3100 Thunder Corners, Eclipse, Georgia, 39923-8325, US', 'lpatterson@easystuffinc.com', 1, 2),
    ('Thomas Evans', '3671 Tawny Quay, Atlas, Yukon, Y2C 2Q0, CA', 'tevans@easystuffinc.com', 1, 3),
    ('Margaret Ramirez', '1914 Emerald Branch Wharf, Fawnskin, Britsh Columbia, V5Y 6X1, CA', 'ramirezman@gmale.com', 2, 8),
    ('Jean Davis', '3952 Harvest Lookout, Purchase, Alberta, T9Z 4H8, CA', 'jdavis@easystuffinc.com', 1, 7),
    ('Clarence Flores', '2688 Dewy Embers Avenue, Moons, Florida, 32523-0176, US', 'cflores@easystuffinc.com', 1, 1),
    ('Steve Powell', '6767 Umber Woods, Blazing Place, Texas, 78298-2044, US', 'spowell@easystuffinc.com', 1, 3),
    ('Jesse Martin', '693 Lost Hills Mount, Teapot Dome, Mississippi, 39380-9892, US', 'martin@brownmartinmiller.com', 3, 5),
    ('Russell Cooper', '2411 Old Cape, Minimum, North Dakota, 58214-9348, US', 'cooperr@gmale.com', 2, 8),
    ('James Alexander', '3088 Gentle Impasse, Foul Rift, Pennsylvania, 18051-9474, US', 'alexandria@hutmail.com', 2, 9),
    ('Wanda Miller', '7088 Golden Close, Ogeecheeton, Minnesota, 56792-4939, US', 'miller@brownmartinmiller.com', 3, 5),
    ('Elizabeth Howard', '6511 Quiet Canyon, Highway Village, Newfoundland, A0R 2Z0, CA', 'ehoward@easystuffinc.com', 1, 5),
    ('Stephanie Price', '5196 Green Apple Line, Ernfold, New Brunswick, E4T 6J5, CA', 'sprice@easystuffinc.com', 1, 3),
    ('Lois Stewart', '2276 Pleasant Trail, Hell Gate, California, 91199-2508, US', 'loisstewart@brownmartinmiller.com', 3, 2),
    ('Willie Williams', '2446 Cotton Ridge, Bay Roberts, Texas, 75477-0910, US', 'wwilliams@male.com', 2, 8),
    ('Randy Hall', '4438 Misty Forest Heath, Cuzzie, West Virginia, 24878-7888, US', 'rhall@easystuffinc.com', 1, 2),
    ('Joseph Richardson', '81 Rocky Carrefour, Central Butte, Delaware, 19835-6945, US', 'not_richarddaughter@yahooo.com', 2, 9),
    ('Gloria Morgan', '8331 Amber Chase, Hogtown, New Brunswick, E1G 1I4, CA', 'gmorgan@easystuffinc.com', 1, 4),
    ('Wayne Griffin', '9736 Grand Barn Bend, Old Trap, South Carolina, 29152-7599, US', 'wgriffin@easystuffinc.com', 1, 6),
    ('Jennifer Scott', '1233 Velvet Autumn Road, Rivers, Alberta, T8N 6M9, CA', 'jscott@easystuffinc.com', 1, 7),
    ('Terry Ross', '2431 Blue Dell, Bear Dance, Wyoming, 82767-9188, US', 'tross@easystuffinc.com', 1, 9),
    ('Jeffrey Jackson', '7317 Cozy Farms, Frontier, Hawaii, 96737-3137, US', 'jjackson@easystuffinc.com', 1, 6),
    ('Gerald Perez', '863 Heather Sky Via, Cutalong, Nunavut, X7J 4N8, CA', 'gperez@easystuffinc.com', 1, 7),
    ('Harold Taylor', '6200 High Log Mountain, Burning Tree, Minnesota, 56169-6013, US', 'tailor@homeserverz.com', 2, 8),
    ('Eugene Turner', '9925 Dusty Treasure Walk, Sublimity, Minnesota, 55436-5256, US', 'eturner@easystuffinc.com', 1, 6),
    ('Dorothy Anderson', '8988 Sunny Pony Townline, Roche Percee, Saskatchewan, S7K 2J8, CA', 'danderson@easystuffinc.com', 1, 7),
    ('Todd Henderson', '3436 Fallen Berry Park, Doughboy, Oklahoma, 73357-0953, US', 'welcome.back@todd.com', 2, 9),
    ('Theresa Carter', '1398 Lazy Rise Dale, Flugrath, Britsh Columbia, V9C 4I0, CA', 'tcarter@easystuffinc.com', 1, 3);


-- Random names generated with http://random-name-generator.info/random
-- Random addresses generated with http://names.igopaygo.com/street/north_american_address
