for repo in rhel-7-server-rpms rhel-7-server-extras-rpms
do
createrepo -v /data/repos/${repo} -o /data/repos/${repo}
done
