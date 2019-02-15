kill -9 `ps -ef | grep hexo | grep -v grep |awk '{print $2}'`
nohup hexo s &

