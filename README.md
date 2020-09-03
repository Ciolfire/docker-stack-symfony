Configuration
=============

PART 0 : Minimum configuration needed for the Docker installation
------
### 0.
Please note that you cannot use Docker and Virtualbox at the same time.  
If you need to use both, install the project on a VM, the procedure will be the same thanks to docker.  
Make sure to disable any apache/nginx/mysql service or the container will not be created correctly.  
### 1.
Get docker and docker-compose.  
https://www.docker.com/products/docker-desktop  
### 2.
Get git.  
https://git-scm.com/  

PART I : Basic installation
---------------------------
### 1.
Get the repository (on your host, it will be muche easier to work on it like that)  
`git clone  https://github.com/ciolfire/docker-stack-symfony`  
Rename the previous repository folder as `symfony`
### 2.
Move to the project folder:  
`cd docker-stack-symfony`  
Get the symfony application you want to use
`git clone  https://github.com/xxx/yyy`  
Take a look at the `.env` file and overwrite all the default variable you want (mysql root password, database names, ...)
Build the project:  
`docker-compose build`  
Create and start the containers:  
`docker-compose up -d`  
### 3.
First add the adress of the project to your host file (/etc/hosts on unix, widows/system32/drivers/ on windows).  
Then check that the project work on symfony.localhost.  
php my admin should be available on localhost:8081.  
### 4.
Now we need to configure the database.  
First, let your container start correctly. push_kannel might need some time to be ready, since it rely on push_db to be ready to accept connections.  
You should do a `docker ps` and wait for it to start.  
Then do a `docker logs push_kannel` and check if the line `INFO: MAIN: Start-up done, entering mainloop` is displayed.  
Next step is to generate the kannel db: `docker exec -d push_kannel /usr/local/sbin/sqlbox -v 1 /kannel/conf-kannel/sqlbox.conf`  
Again, check with `docker logs push_kannel` that everything worked fine.  
Last step to have a running kannel is to use `docker exec -d push_kannel /usr/local/sbin/smsbox -v 1 /kannel/conf-kannel/kannel.conf`.  
You can remove the `-d` if you want to keep track of the logs, or simply use `docker logs push_kannel` as usual.  
If everything went fine, your kannel service is running and working.  
