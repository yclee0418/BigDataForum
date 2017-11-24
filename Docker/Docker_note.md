建立Image :
  1. 將 ubuntu 最新的Image拉下來: docker run -it ubuntu bash
  2. 拉下來的 ubuntu 裡不會安裝任何東西，在bash裡自行安裝需要的套件
    * apt update
    * apt-get install net-tools => install ifconfig
    * apt-get install iputils-ping => install ping
    * apt-get install vim => install vim
    * apt install openssh-server
  3. exit 跳出 bash 後，用docker ps -a 查看 container ID
  4. 將已安裝之版本建立自己的Image版本: docker commit -m "install sshd" containerID ubuntu:my

安裝 sshd : 
  1. docker run -h hadoop1 -p 52022:22 -it ubuntu:my bash
  2. apt install openssh-server
  3. service ssh status
  4. service ssh restart => run if sshd is not run
  5. useradd -m hduser, passwd hduser => create hduser account
  6. usermod -aG sudo hduser => grant sudo privilege to hduser
  7. apt install sudo => install sudo

使用 putty 登入 :
  1. 確認 container 已啟動 (docker ps)，若沒有則 docker run -h hadoop1 -p 52022:22 -it ubuntu:my bash
  2. 確認 sshd 已啟動
  3. putty localhost:52022 (視docker run container 時 -p 參數而定)
  4. set SHELL=/bin/bash (可由 env 看到使用的shell，故修改變數後重新登入)
  5. exec /bin/bash --login => putty 預設登入用 sh shell，很難用；改用 bash shell
  6. pscp local.txt hduser@localhost:/home/hduser/Downloads => 上傳檔案
  
  
  
使用已建立之容器進行後續作業
  1. docker container start CONTAINER_ID
  2. docker container attach CONTAINER_ID
