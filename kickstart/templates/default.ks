# vim: ts=4 nowrap:

install
text
reboot
url --mirrorlist http://mirrorlist.centos.org/?cc=at&arch=x86_64&repo=os&release=7
repo --name extras --mirrorlist http://mirrorlist.centos.org/?cc=at&arch=x86_64&repo=extras&release=7
repo --name updates --mirrorlist http://mirrorlist.centos.org/?cc=at&arch=x86_64&repo=updates&release=7
repo --name epel --mirrorlist http://mirrors.fedoraproject.org/metalink?repo=epel-7&arch=x86_64

# System language
lang en_GB.UTF-8 --addsupport=de_AT.UTF-8
keyboard --vckeymap=at-nodeadkeys --xlayouts='at (nodeadkeys)','us','at (mac)','gb (mac_intl)'
timezone Etc/UTC --isUtc

sshpw --username root --lock --iscrypted $6$C74dtlSq.DLs6xPr$FprWENXxBbFJVQcfEfeuVIOQ8znO0HirbRzzgnsF8s5.Ia.E5vPUXPvsQ.yD5yFk.yCHB8ecfVvlkJ6.8Uuwj0
sshpw --username inst --iscrypted $6$dE0toHpyv7fnbqYi$fqLzbpQ3J3T.a3E7c7qrGmqm1B9U9eijR2Qw6olwTU.5n7QYuyAB4yOPxcwGjBmRzKXyMCxzBJ1G0FP4RzwHp1
rootpw --iscrypted $6$5vzcYesbqfo04ICK$uYmjKw6OSZ6Zzftvi8wasbNs2Ffm6MIUi3OwJg2urla9OhvaFV3Wp6t5XDC31jr7eGXyUBvzeAwEOtpA59QYw/
user --groups=wheel --name=mafalb --password=$6$OcP0K8rLifAEWkgG$/g7OgIzKFALBVP0He1f838WYaKeOdMdZ3dqVWFHvmt0M93Caq8FbMdjU1Oz6X6UaClzi8L4vEtdyoruEJoCof0 --iscrypted --uid=10000 --gecos="Markus Falb" --gid=10000


firewall --enabled --service=ssh
services --enabled=acpid,sshd,chronyd
auth --enableshadow --enablecache --passalgo=sha512
selinux --enforcing
bootloader "crashkernel=auto" --location=mbr
firstboot --disable
skipx

network --device link {% if not ipv4 %}--noipv4{% endif %} --hostname={{ fqdn }} --ipv6={{ ipv6_address }} --ipv6gateway={{ ipv6_gateway }} --nameserver {{ nameserver|join(",") }} --onboot yes

zerombr
clearpart --all --initlabel

part /boot --ondisk {{ disk }} --size 512 --asprimary --label boot
part pv.00 --ondisk {{ disk }} --size 12000 --grow --asprimary

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
install -d --owner=mafalb --group=mafalb --mode=700 /home/mafalb/.ssh

cat > /root/.ssh/authorized_keys << PUBLIC_KEY
    ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEAqBKLbgm/95GnBGIMYWgE2EJAKRdczIQn/1os53H9wHR7/d8BN4NUQVaeKvoBku/FR1SaC/K8iEE/YDrOcq4oQ5Q8sDOYpf8iMlfit8uo09ZtY4REk0zo54VwDGsaxJuk7fZi4UVWAVe73zH8Af/zoFwA4kp7Lg5UWDrk0wAz3WdSROu7Eh/xvBTdwoJTV9bOT+DjB7IdyGjBpT3fAnIkBdDPcFfhVCiDPGaL3r6E6T/FmjwXIK7urrRdggQ0aVdujwNrCemVODouTe0dyfPGtx+yN/yHLe1PSY+MuIdQGpcXqLHFwYTLwK/X7NG+Mq2+geLYyaSB5XlStMjFkZrpuQ== mafalb
    PUBLIC_KEY

cat > /home/mafalb/.ssh/authorized_keys <<- PUBLIC_KEY
	ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEAqBKLbgm/95GnBGIMYWgE2EJAKRdczIQn/1os53H9wHR7/d8BN4NUQVaeKvoBku/FR1SaC/K8iEE/YDrOcq4oQ5Q8sDOYpf8iMlfit8uo09ZtY4REk0zo54VwDGsaxJuk7fZi4UVWAVe73zH8Af/zoFwA4kp7Lg5UWDrk0wAz3WdSROu7Eh/xvBTdwoJTV9bOT+DjB7IdyGjBpT3fAnIkBdDPcFfhVCiDPGaL3r6E6T/FmjwXIK7urrRdggQ0aVdujwNrCemVODouTe0dyfPGtx+yN/yHLe1PSY+MuIdQGpcXqLHFwYTLwK/X7NG+Mq2+geLYyaSB5XlStMjFkZrpuQ== mafalb
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
