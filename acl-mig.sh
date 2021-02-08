USER=usernamehere
PASSWORD='passwordhere'
NSX=nsxmanagerheree

#txt files cleanup

rm -rf *.txt


#acl.list file normalization

cp acl.list acltest.txt

sed -i 's/ 255.255.255.252/\\\/30/g' acltest.txt
sed -i 's/ 255.255.255.248/\\\/29/g' acltest.txt
sed -i 's/ 255.255.255.240/\\\/28/g' acltest.txt
sed -i 's/ 255.255.255.224/\\\/27/g' acltest.txt
sed -i 's/ 255.255.255.196/\\\/26/g' acltest.txt
sed -i 's/ 255.255.255.128/\\\/25/g' acltest.txt
sed -i 's/ 255.255.255.0/\\\/24/g' acltest.txt
sed -i 's/ 255.255.254.0/\\\/23/g' acltest.txt
sed -i 's/ 255.255.252.0/\\\/22/g' acltest.txt
sed -i 's/ 255.255.248.0/\\\/21/g' acltest.txt
sed -i 's/ 255.255.240.0/\\\/20/g' acltest.txt
sed -i 's/ 255.255.224.0/\\\/19/g' acltest.txt
sed -i 's/ 255.255.196.0/\\\/18/g' acltest.txt
sed -i 's/ 255.255.128.0/\\\/17/g' acltest.txt
sed -i 's/ 255.255.0.0/\\\/16/g' acltest.txt
sed -i 's/ 255.254.0.0/\\\/15/g' acltest.txt
sed -i 's/ 255.252.0.0/\\\/14/g' acltest.txt

sed -i 's/ host//g' acltest.txt

sed -i 's/any/ANY/g' acltest.txt

sed -i 's/ip/ANY/g' acltest.txt

sed -i 's/ //' acltest.txt

sed -i 's/ /,/g' acltest.txt



awk -F, '{ print $1","$2","$3","$4","$6","$7","$5","$8","$9}' acltest.txt > acltest2.txt

sed -i 's/permit/ALLOW/g' acltest2.txt
sed -i 's/deny/DROP/g' acltest2.txt

#Include the services objects conversion here
#
#Important: Inclue \\\ before / directory path due to regex and sed usage
#
#Eg.: /home should be written as \\\/home
#


sed -i 's/icmp,,/\\\/infra\\\/services\\\/ICMP-ALL/g' acltest2.txt

sed -i 's/tcp,eq,ftp-data/\\\/infra\\\/services\\\/FTP/g' acltest2.txt
sed -i 's/tcp,eq,ftp/\\\/infra\\\/services\\\/FTP/g' acltest2.txt
sed -i 's/tcp,eq,22/\\\/infra\\\/services\\\/SSH/g' acltest2.txt
sed -i 's/tcp,eq,telnet/\\\/infra\\\/services\\\/TELNET/g' acltest2.txt

sed -i 's/tcp,eq,53/\\\/infra\\\/services\\\/DNS/g' acltest2.txt

sed -i 's/udp,eq,53/\\\/infra\\\/services\\\/DNS-UDP/g' acltest2.txt

sed -i 's/tcp,eq,80/\\\/infra\\\/services\\\/HTTP/g' acltest2.txt

sed -i 's/tcp,eq,123/\\\/infra\\\/services\\\/NTP/g' acltest2.txt

sed -i 's/tcp,eq,443/\\\/infra\\\/services\\\/HTTPS/g' acltest2.txt

sed -i 's/tcp,eq,3389/\\\/infra\\\/services\\\/RDP/g' acltest2.txt


sed -i 's/tcp,,/ANY,TCP/g' acltest2.txt
sed -i 's/udp,,/ANY,UDP/g' acltest2.txt



echo `cat acltest2.txt`

#DFW configuration before script

curl -k --user $USER:$PASSWORD https://$NSX/policy/api/v1/infra/domains/default/security-policies | grep '"id"' > section_id.txt
curl -k --user $USER:$PASSWORD https://$NSX/policy/api/v1/infra/domains/default/security-policies | grep '"display_name"' > section_display_name.txt
curl -k --user $USER:$PASSWORD https://$NSX/policy/api/v1/infra/domains/default/security-policies | grep '"path"' > path.txt

paste -d " " section_id.txt section_display_name.txt path.txt > section.list

#GNU
sed -i 's/ //g' section.list
sed -i 's/:/,/g' section.list
sed -i 's/"//g' section.list

#MACOS

#sed -i'' -e 's/ //g' section.list
#sed -i'' -e  's/:/,/g' section.list
#sed -i'' -e 's/"//g' section.list

echo `cat section.list`


SECTION="section.list"
#echo `cat $PATH`

for SECTIONVAR in `cat $SECTION`

do

ID01=`echo $SECTIONVAR | cut -f2 -d","`
DISPLAYNAME01=`echo $SECTIONVAR | cut -f4 -d","`
PATH01=`echo $SECTIONVAR | cut -f6 -d","`

echo $ID01
echo $PATH01

curl -k --user $USER:$PASSWORD https://$NSX/policy/api/v1$PATH01 >> rules-orig.txt
#curl -k --user $USER:$PASSWORD https://$NSX/policy/api/v1/infra/domains/default/security-policies/$ID01 >> rules-orig.txt

echo `cat rules-orig.txt`

done


#
#DFW Configuration
#

ACL="acltest2.txt"
RULESEQ=0

for ACLLINE in `cat $ACL`

do

RULESEQ=$(( $RULESEQ + 1))

SECTIONVAR=`echo $ACLLINE | cut -f2 -d","`
ACTIONVAR=`echo $ACLLINE | cut -f4 -d","`
SOURCEVAR=`echo $ACLLINE | cut -f5 -d","`
DESTINATIONVAR=`echo $ACLLINE | cut -f6 -d","`
SERVICEVAR=`echo $ACLLINE | cut -f7 -d","`
PROTOVAR=`echo $ACLLINE | cut -f8 -d","`
RULEVAR=`echo $SECTIONVAR\_$RULESEQ`

ICMP="\/infra\/services\/ICMP-ALL"

cp rule-dfw.template rule-dfw-$RULEVAR.txt

#

if [[ "$SERVICEVAR" == "$ICMP" ]] || [[ -z "$PROTOVAR" ]];
then

sed -i -e '17,20d' rule-dfw-$RULEVAR.txt

echo "This DFW Rule is using the $SERVICEVAR"

else

echo "This DFW Rule is using the $SERVICEVAR and Protocol $PROTOVAR";

fi

echo "Configuring $RULEVAR Source: $SOURCEVAR  Destination: $DESTINATIONVAR  Service: $SERVICEVAR  Protocol: $PROTOVAR"

sed -i s/RULEVAR/$RULEVAR/ rule-dfw-$RULEVAR.txt
sed -i s/SECTIONVAR/$SECTIONVAR/ rule-dfw-$RULEVAR.txt
sed -i s/ACTIONVAR/$ACTIONVAR/ rule-dfw-$RULEVAR.txt
sed -i s/SOURCEVAR/$SOURCEVAR/ rule-dfw-$RULEVAR.txt
sed -i s/DESTINATIONVAR/$DESTINATIONVAR/ rule-dfw-$RULEVAR.txt
sed -i s/SERVICEVAR/$SERVICEVAR/ rule-dfw-$RULEVAR.txt
sed -i s/PROTOVAR/$PROTOVAR/ rule-dfw-$RULEVAR.txt
sed -i s/DESCVAR/Migration_of_$SECTIONVAR$RULESEQ/ rule-dfw-$RULEVAR.txt

curl -k --user $USER:$PASSWORD https://$NSX/policy/api/v1/infra/domains/default/security-policies/$SECTIONVAR -X PATCH --data @rule-dfw-$RULEVAR.txt -H "Content-Type: application/json"

sleep 2

done


#Clean up

read -p "Do you want to delete the .txt files created for migration? (Y/N)" -n 1 -r CHOICE
echo    #
if [[ $CHOICE =~ ^[Yy]$ ]];

then

echo "Deleting .txt files"
rm -rf *.txt

else
echo "Saving the .txt files"

fi

echo "Task completed! $RULESEQ rule(s) have been configured in NSX $NSX."
