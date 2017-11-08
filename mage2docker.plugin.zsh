# Mage2Docker
#
# Plugin for Oh-My-Zsh

_docker_get_container_name () {
	docker ps | awk '{if(NR>1) print $NF}'
}

_mage2docker_magento () {
	compadd `docker exec $1 bin/magento list | sed 's/\x1b\[[0-9;]*m//g' | awk '{if(NR > 15 && /:/) print $1}'`
}

_mage2docker_mage() {
	docker exec -it -u www-data $1 bin/magento $2
}

_mage2docker_container_ip() {
	docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' $1
}

_mage2docker_report() {
	compadd `docker exec -u www-data $1 ls -tr var/report`
}

_mage2docker_log(){
	compadd `docker exec -u www-data $1 ls -tr var/log`
}

_mage2docker_mysql_data() {
	printf '%s ' 'User name:'
	read user
	printf '%s ' 'Database name:'
	read database
	printf '%s ' 'file name:'
	read file
}

_mage2docker() {

    local curcontext="$curcontext" state line
    typeset -A opt_args

    _arguments \
        '1: :->containerName'\
        '2: :->command' \
	'3: :->options'

    case $state in
    containerName)
        compadd $(_docker_get_container_name)
    ;;
    command)
	compadd "$@" bash-www bash logs magento mage mage-cache mage-reindex mage-di mage-upgrade mage-report mage-log grunt watch rename rm restart stop inspect top mysqldump mysql ip
    ;;
    options)
        case $words[3] in
        mage)
            _mage2docker_magento $words[2]
        ;;
	mage-report)
	    _mage2docker_report $words[2]
	;;
	mage-log)
	    _mage2docker_log $words[2]
	;;
	esac
    esac
}


mage2docker () {
   case $2 in
   restart|stop|inspect|rm|rename|top)
	echo cmd=$2
	docker $2 $1
	;;
   logs)
	docker logs -f $1
	;;
   bash)
	docker exec -it -u root $1 bash
	;;
   bash-www)
	docker exec -it -u www-data $1 bash
	;;
   magento)
	docker exec -it -u www-data $1 bin/magento
	;;
   mage)$
	_mage2docker_mage $1 $3
   	;;
   mage-cache)
	_mage2docker_mage $1 cache:clean
   	;;
   mage-reindex)
	_mage2docker_mage $1 indexer:reindex
   	;;
   mage-upgrade)
	_mage2docker_mage $1 setup:upgrade
	;;
   mage-di)
	_mage2docker_mage $1 setup:di:compile
	;;
   mage-deploy)
	_mage2docker_mage $1 setup:static-content:deploy
	;;
   grunt)
	docker exec -it -u www-data $1 grunt
	;;
   watch)
	docker exec -it -u www-data $1 grunt watch
	;;
   mage-report)
	docker exec -it -u www-data $1 cat var/report/$3
   ;;
   mage-log)
	docker exec -it -u www-data $1 tail -f var/log/$3
   ;;
	 #new informations
	 ip)
	_mage2docker_container_ip $1
	 ;;
	 mysqldump)
	_mage2docker_mysql_data
	mysqldump -h$(_mage2docker_container_ip $1) -u$user -p $database > $file
	echo "Success database backup was created"
	 ;;
	 mysql)
	_mage2docker_mysql_data
	mysql -h$(_mage2docker_container_ip $1) -u$user -p $database < $file
	echo "Success database restore"
	 ;;
   *)
	if [ ! "$1" ]; then
   		docker ps
	else
		docker exec -it -u www-data $1 bash
	fi
   	;;
   esac

}

if type "docker" > /dev/null; then

	compdef _mage2docker mage2docker
	alias m2d='mage2docker'

else
	echo "mage2docker - docker is not installed"
fi
