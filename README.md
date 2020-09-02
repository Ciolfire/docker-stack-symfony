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
rename the previous repository folder as `symfony`
### 2.
move to the project folder:  
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
### 5.
Now, Symfony need to know the configuration you just created, you do that by modifying the file `config/packages/doctrine.yaml`. You will see two lines like this:  
`url: '%env(resolve:YOUR_DB_URL)%'`  
This link to the same variable from your `.env` file, at the root of the repository.  
Find the line `SYMFONY_DB_URL=mysql://user:pwd@push_db:3306/database_name` and replace the differents values by your local configuration.  
Same thing for the line `KANNEL_DB_URL=mysql://user:pwd@push_db:3306/database_name`

As an example, if you named your database `symfony`, and connect with the user `optelo` and the password `p4ssw0rd` you should write:

`SYMFONY_DB_URL=mysql://optelo:p4ssw0rd@push_db:3306/symfony`

`(const in symfony)=(managment system)://(user):(password)@(adress(here, container)):(port)/(database name)`


If you still have issues with connecting, try to clear the cache:  
`php bin/console cache:clear`  
### 6.
Now, we have an empty database that we still need to generate. For this, one simple solution:
`php bin/console doctrine:migration:migrate`  
Assuming that the operation was errorless all your table were created. You will still need to create an user to connect:  
`php bin/console security:encode-password` First generate a password compatible with your application encryption.  
There are three entity you *absolutely* need to initialize to be able to login:  

1. An `user`, you need an email and the password you generated previously.
2. A `company`, preferably the first one should be Optelo. id_admin should be the one of the user you just created (probably 1) and `is_credit` should be 0.
3. A `branch`, I advice to name it "dev". `moderator_id` is again your user id, `parent_company_id` is your company id.
4. Finally get back to your user and add it to the branch you just created by allocating him this branch id as `branch_id`.
### 7.
Now we need to execute the update on the kannel db, for this, we first need to connect to the database container:  
`docker exec -it push_db sh`
Then we feed the update to the table:  
`mysql -p < /scripts/kannel_update.sql`  
Let's take this opportunity to initialize the push base:
`mysql -p < /scripts/push_init.sql`  

### 8.
Try to login. Can you see the Dashboard ? Congrats.


PART III : Temp
---------
Noted for later: msgdata of the table snd-msg MUST be of type BLOB otherwise the special character will NOT be displayed and will be replaced by '?'

It's mandatory to rename the following part of the trigger "after_sent_sms_insert" on sent_sms, including the correct classic push database name, or just remove it if only the symfony version will be used:

The column campaign snd_campaign_id should be renamed snd_sending_id

SIDENOTE FOR LATER: All the column should be cleaned and renamed without the 'snd_' prefix which is un-needed. All the snd_STATUS are redundant with the snd_last and snd_last_time, so it should ALSO be reworked. snd_sequence_number should be modified to reflect the number_id
