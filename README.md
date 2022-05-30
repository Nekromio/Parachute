# Parachute
The menu of parachutes is different for each team

Video demonstration
https://youtu.be/uDPEFDxGIQA

//*******************************************//

Плагин создан при поддержки проекта https://ggwp.site/
Это портал с лучшими моделями для Counter-Strike Source

Ссылка на парашюты https://ggwp.site/product-category/parashjuty/

//*******************************************//

В файле /cfg/sourcemod/parachute_ggwp.cfg есть переменнная

// 1 использовать MySQL базу, 0 - использовать SqLite локальную базу
// -
sm_parachute_mysql "0"

Выбираем какой тип подключения вам нужен, MySQL это база данных на стороннем сайте, а SqLite это локальная база сервера

Потом идём по пути /addons/sourcemod/configs/databases.cfg

В этом файле вставляем нужен столбец ПЕРЕД последней "}" закрывающейся скобкой

Для MySQL
//****//
	"parachute"
	{ 
		"driver" "mysql" 
		"host" "Ваш ip адрес базы" 
		"database" "Имя базы данных" 
		"user" "Пользователь базы данных" 
		"pass" "Пароль от базы данных" 
		//"timeout" "0" 
		"port" "3306"
	}
//****//

Для SqLite
//****//

	"parachute_lite"
	{ 
		"driver"			"sqlite"
		"host"				"localhost"
		"database"			"parachute"
		"user"				"root"
		"pass"				""
		//"timeout"			"0"
		//"port"			"0"
	}

//****//

Обащаю ваше внимание на то, что для MySQL ключ в databases это "parachute", а для SqLite это "parachute_lite"


/// EN

//*******************************************//

The plugin was created with the support of the project https://ggwp.site/
This is a portal with the best models for Counter-Strike Source

Link to parachutes https://ggwp.site/product-category/parashjuty/

//*******************************************//

In the file /cfg/sourcemod/parachute_ggwp.cfg there is a variable

// 1 use MySQL database, 0 - use SQLite local database
// -
sm_parachute_mysql "0"

Choose which type of connection you need, MySQL is a database on a third-party site, and SQLite is a local server database

Then follow the path /addons/sourcemod/configs/databases.cfg

In this file, we insert the necessary column BEFORE the last "}" closing parenthesis

For MySQL
	//****//
	"parachute"
	{
		"driver" "mysql"
		"host" "Your database ip address"
		"database" "Database name"
		"user" "Database user"
		"pass" "Database password"
		//"timeout" "0"
		"port" "3306"
	}
	//****//

For SQLite
//****//

	"parachute_lite"
	{
		"driver" "sqlite"
		"host" "localhost"
		"database" "parachute"
		"user" "root"
		"pass" ""
		//"timeout" "0"
		//"port" "0"
	}

//****//

I would like to draw your attention to the fact that for MySQL, the key in databases is "parachute", and for SQLite it is "parachute_lite"
