# Parachute
The menu of parachutes is different for each team

Video demonstration
https://youtu.be/uDPEFDxGIQA

# ru

Плагин создан при поддержки проекта https://ggwp.site/
Это портал с лучшими моделями для Counter-Strike Source

Ссылка на парашюты https://ggwp.site/product-category/parashjuty/

Для MySQL идём по пути /addons/sourcemod/configs/databases.cfg

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

Для SqLite ничего делать не нужено, у вас автоматически создатся локальная база данных по пути /cstrike/addons/sourcemod/data/sqlite/parachute.sq3

