for repo in rhel-7-server-rpms rhel-7-server-extras-rpms
do
  reposync --gpgcheck -lm --repoid=${repo} --download_path=/data/repos/
done
