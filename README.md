# acl-mig_v0.1
# maintained by dfgpsantos

#This script helps to convert cisco ACLs into NSX DFW rules.
#It's a bash shell script that uses sed and curl to convert the cisco acl into a NSX DFW rule.
#I've tested it using Centos 7/8 you might need to change something to adjuts the sintax in other OS's.
#
#Here's the step by step usage guide of this script
#1-) Provide the original acl list using the file acl.list. There's an example file for reference.
#2-) Inform the NSX address, username and password allowed to create DFW rules through API calls
#3-) include any services that are not listed in the original list. There's an initial list but it might be needed to include 
#others like LDAP, MySQL, Oracle and etc. Heres an example using LDAP sed -i 's/tcp,eq,389/\\\/infra\\\/services\\\/LDAP/g' acltest2.txt
#The usage of \ is necessary due to regex over sed.
#So the original path address in nsx /infra/services/LDAP should be written as: \\\/infra\\\/services\\\/LDAP
#
#In the end of file it'll prompted to keep or discard the .txt files used to convert the ACLs and to make the API calls in NSX.
#
#Happy ACL to DFW converting!!! :)
