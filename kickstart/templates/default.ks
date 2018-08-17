# vim: ts=4 nowrap:

install
text
reboot
url --mirrorlist http://mirrorlist.centos.org/?cc=at&arch=$basearch&repo=os&release=$releasever
repo --name updates --mirrorlist http://mirrorlist.centos.org/?cc=at&arch=$basearch&repo=updates&release=$releasever
#repo --name extras --mirrorlist http://mirrorlist.centos.org/?cc=at&arch=$basearch&repo=extras&release=$releasever
#repo --name epel --mirrorlist http://mirrors.fedoraproject.org/metalink?repo=epel-$releasever&arch=$basearch

# System language
lang en_GB.UTF-8 --addsupport=de_AT.UTF-8
keyboard --vckeymap=at-nodeadkeys --xlayouts='at (nodeadkeys)','us','at (mac)','gb (mac_intl)'
timezone Etc/UTC --isUtc

sshpw --username root --lock --iscrypted {{ bootstrap.initialpw.root }}
sshpw --username inst --iscrypted {{ bootstrap.initialpw.root }}
rootpw --iscrypted {{ bootstrap.initialpw.root }}
user --groups wheel --name {{ bootstrap.initial_user }} --uid 10000 --gid 10000 --iscrypted {{ bootstrap.initialpw.initial_user }}


firewall --enabled --service=ssh
services --enabled=acpid,sshd,chronyd
auth --enableshadow --enablecache --passalgo=sha512
selinux --enforcing
bootloader "crashkernel=auto" --location=mbr
firstboot --disable
skipx

network --device link {% if not bootstrap.ipv4 %}--noipv4{% endif %} --hostname={{ inventory_hostname }} --ipv6={{ bootstrap.ipv6_address }} --ipv6gateway={{ bootstrap.ipv6_gateway }} --nameserver {{ bootstrap.nameserver|join(",") }} --onboot yes

zerombr
clearpart --all --initlabel

{% if bootstrap.disk.type == "raid1" %}
{% for disk in bootstrap.disk.disks %}
part raid.0{{ loop.index }} --ondisk {{ disk }} --size 512 --asprimary
{% endfor %}
raid /boot --level 1 --device 0 {% for disk in bootstrap.disk.disks %} raid.0{{ loop.index }} {% endfor %}

{% for disk in bootstrap.disk.disks %}
part raid.1{{ loop.index }} --ondisk sda --size 30000 --grow --asprimary
{% endfor %}
raid pv.00 --level 1 --device 1 {% for disk in bootstrap.disk.disks %} raid.0{{ loop.index }} {% endfor %}
{% endif %}

{% if bootstrap.disk.type == "single" %}
part /boot --ondisk {{ bootstrap.disk.disks[0] }} --size 512 --asprimary --label boot
part pv.00 --ondisk {{ bootstrap.disk.disks[0] }} --size 12000 --grow --asprimary
{% endif %}

volgroup lvm.{{ inventory_hostname_short }} pv.00

# system partitions
logvol /              --fstype xfs  --name wurzel --size 3000 --vgname lvm.{{ inventory_hostname_short }}
logvol /tmp           --fstype xfs  --name tmp    --size 1000 --vgname lvm.{{ inventory_hostname_short }} --fsoptions="defaults,nodev,nosuid,noexec"
logvol /var           --fstype xfs  --name var    --size 1000 --vgname lvm.{{ inventory_hostname_short }} --fsoptions="defaults,nodev,nosuid"
logvol /var/log       --fstype xfs  --name log    --size 1000 --vgname lvm.{{ inventory_hostname_short }} --fsoptions="defaults,nodev,nosuid,noexec"
logvol /var/log/audit --fstype xfs  --name audit  --size 500  --vgname lvm.{{ inventory_hostname_short }} --fsoptions="defaults,nodev,nosuid,noexec"
logvol swap           --fstype swap --name swap   --size 1000 --vgname lvm.{{ inventory_hostname_short }}
logvol /home          --fstype xfs --name home    --size 100 --vgname lvm.{{ inventory_hostname_short }} --fsoptions="defaults,nodev,nosuid,noexec"


%pre --log=/tmp/ks-pre.log
set -x -v
%end


%post --logfile /root/ks-post.log
set -x -v

# Create .ssh
install -d --mode=700 /root/.ssh
install -d --owner={{ bootstrap.initial_user }} --group={{ bootstrap.initial_user }} --mode=700 /home/{{ bootstrap.initial_user }}/.ssh

cat > /root/.ssh/authorized_keys << PUBLIC_KEY
	{{ bootstrap.ssh_pubkey.initial_user }}
    PUBLIC_KEY

cat > /home/{{ bootstrap.initial_user }}/.ssh/authorized_keys <<- PUBLIC_KEY
	{{ bootstrap.ssh_pubkey.initial_user }}
	PUBLIC_KEY

# Disable authentication with Passwords
sed -i 's&^#\?PermitRootLogin[ \t]*.*&PermitRootLogin without-password&' /etc/ssh/sshd_config
sed -i "s&^PasswordAuthentication[ \t]*.*&PasswordAuthentication no&g" /etc/ssh/sshd_config

%end

%post --nochroot --logfile /mnt/sysimage/root/ks-post-nochroot.log
set -x -v

# Copy anacondas logfiles
cp /tmp/*log /mnt/sysimage/root/

# Copy the pre log
cp /tmp/ks-pre.log /mnt/sysimage/root/ks-pre.log
cp /tmp/network.ks /mnt/sysimage/root/
cp /tmp/partitions.ks /mnt/sysimage/root/

# Copy the original ks file (that's me!)
cp /run/install/ks.cfg /mnt/sysimage/root/

%end

%packages
@Core --nodefaults
acpid
openssh-server
chrony
%end

%addon com_redhat_kdump --enable --reserve-mb=auto
%end

%addon org_fedora_oscap
    content-type = scap-security-guide
    profile = default
%end
