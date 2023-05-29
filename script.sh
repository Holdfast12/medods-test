#!/bin/bash

# 1. Написать BASH-скрипт который скачивает файл
# https://raw.githubusercontent.com/GreatMedivack/files/master/list.out из репозитория.

curl https://raw.githubusercontent.com/GreatMedivack/files/master/list.out > list.out


# 2. Создает на его основе два файла с именами **SERVER_DATE_failed.out** и **SERVER_DATE_running.out**,
# где SERVER это название сервера (передается в скрипт в качестве аргумента, при отсутствии
# аргумента должно выставляться какое-либо значение по умолчанию), а DATE текущая дата в
# формате ДЕНЬ_МЕСЯЦ_ГОД (например 01_09_1939).

# - Первый файл должен содержать только имена тех сервисов (столбец NAME), у которых статус
# (столбец STATUS) равен Error или CrashLoopBackOff.

# - Второй файл должен содержать только имена тех сервисов, у которых статус равен Running.

# *В созданных файлах должны находиться только имена сервисов, данные из других столбцов
# исходного файла не нужны.*

# Удаляет из имен сервисов постфиксы формата -xxxxxxxxxx-xxxxxx если они там есть (например,
# вместо demomed-analysis-service-6f955bff79-cqjv9 должно получиться demomed-analysis-service).


# здесь у меня проверка, была ли передача аргумента для использования в именах файлов
# установка значения "SERVER" в случае, если аргументов получено не было
if [ -z ${1} ]; then
SERVER="SERVER"
else
SERVER=$1
fi

SERVER_DATE="$SERVER"_"$(date '+%d_%m_%Y')"

# первый файл - статусы Error или CrashLoopBackOff
while read line
do
if [[ $(echo $line | awk '{print $3}') == "Error" || $(echo $line | awk '{print $3}') == "CrashLoopBackOff" ]]; then
echo $line | awk '{print $1}' | sed 's/-[[:alnum:]]\{9,10\}-[[:alnum:]]\{5\}$//g'
fi
done < ./list.out > ./"$SERVER_DATE"_"failed.out"


# второй файл - статус Running
while read line
do
if [[ $(echo $line | awk '{print $3}') == "Running" ]]; then
echo $line | awk '{print $1}' | sed 's/-[[:alnum:]]\{9,10\}-[[:alnum:]]\{5\}$//g'
fi
done < ./list.out > ./"$SERVER_DATE"_"running.out"

# 3. Создает файл **SERVER_DATE_report.out** с правами на чтение для всех пользователей со
# следующими строками:
#
# -  Количество работающих сервисов: 0 *# Здесь должно отображаться количество сервисов из
# файла SERVER_DATE_running.out*
#
# - Количество сервисов с ошибками: 0 *# Здесь должно отображаться количество сервисов из
# файла SERVER_DATE_failed.out*
#
# - Имя системного пользователя: User *# Здесь должно отображаться имя пользователя,
# запустившего скрипт*
#
# - Дата: 01/09/20 *# Здесь должна отображаться текущая дата*

echo "Количество работающих сервисов: $(wc -l < ./"$SERVER_DATE"_"running.out")" > ./"$SERVER_DATE"_"report.out"
echo "Количество сервисов с ошибками: $(wc -l < ./"$SERVER_DATE"_"failed.out")" >> ./"$SERVER_DATE"_"report.out"
echo "Имя системного пользователя: $USER" >> ./"$SERVER_DATE"_"report.out"
echo "Дата: $(date '+%d/%m/%y')" >> ./"$SERVER_DATE"_"report.out"
chmod 664 ./"$SERVER_DATE"_"report.out"

# 4. Запаковывает все полученные файлы в архив c именем SERVER_DATE и складывает его в папку
# archives если архива с таким именем еще не существует.

if [[ $(ls | grep archives) != "archives" ]]; then
mkdir ./archives
fi

if [[ $(ls ./archives | grep $SERVER_DATE) != "$SERVER_DATE".tar ]]; then
tar -cf ./archives/"$SERVER_DATE".tar ./"$SERVER_DATE"_*.out
fi

# 5. Удаляет все файлы кроме содержимого папки archives

find . -maxdepth 1 -not -type d -not -name "script.sh" | xargs rm

# 6. Выполняет проверку архива на повреждение и выводит сообщение об успешном завершении
# работы или ошибке.

tar -tf ./archives/"$SERVER_DATE".tar > /dev/null && echo "архив успешно проверен" || echo "архив поврежден"