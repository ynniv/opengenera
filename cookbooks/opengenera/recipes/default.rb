
execute "apt-get-update" do
  command "apt-get update"
  ignore_failure true
  not_if do ::File.exists?('/var/lib/apt/periodic/update-success-stamp') end
end

packages = %w|curl vnc4server nfs-common nfs-server inetutils-inetd blackbox|

packages.each do |pkg|
  package pkg
end

execute "expand-opengenera" do
  cwd "/opt"
  creates "/opt/og2"
  command "tar xfj /vagrant/opengenera2.tar.bz2"
end

execute "download snap4" do
  cwd "/vagrant"
  creates "/vagrant/snap4.tar.gz"
  command "curl -O http://www.unlambda.com/download/genera/snap4.tar.gz"
end

execute "expand snap4" do
  cwd "/opt"
  creates "/opt/snap4"
  command "tar xvfz /vagrant/snap4.tar.gz"
end

cookbook_file "/etc/inetd.conf" do
  source "inetd.conf"
  mode "0644"
end

execute "bounce inetd" do
  command "/etc/init.d/inetutils-inetd restart"
end

execute "set hostname" do
  command "echo 'genera-host' > /etc/hostname; hostname genera-host"
end

cookbook_file "/etc/hosts" do
  source "hosts"
  mode "0644"
end

cookbook_file "/etc/exports" do
  source "exports"
  mode "0644"
end

execute "bounce nfs" do
  command "/etc/init.d/nfs-kernel-server restart"
end

cookbook_file "/opt/snap4/.VLM" do
  source "dotVLM"
  mode "0644"
end

execute "configure og2 image" do
  creates "/var/lib/symbolics"
  command "cp -R /opt/snap4 $SDIR; cp -R /opt/og2/sys.sct $SDIR; mkdir $SDIR/rel-8-5; ln -s $SDIR/sys.sct $SDIR/rel-8-5/sys.sct"
  environment ({ "SDIR" => "/var/lib/symbolics" })
end

execute "create .vnc" do
  command "mkdir -p /root/.vnc"
end

cookbook_file "/root/.vnc/passwd" do
  source "vncpasswd"
  mode "0600"
end

cookbook_file "/root/.vnc/xstartup" do
  source "vncxstartup"
  mode "0755"
end

execute "allow global write to genera files" do
  command "chmod ugo+w -R /var/lib/symbolics/sys.sct"
end

execute "clear vnc.pid on startup" do
  command "echo 'rm -f /root/.vnc/genera-host:1.pid' > /etc/rc.local"
end

execute "start opengenera under vnc" do
  creates "/root/.vnc/genera-host:1.pid"
  command "vncserver"
end
