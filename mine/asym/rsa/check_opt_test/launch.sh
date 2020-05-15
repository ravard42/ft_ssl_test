KNRM="\x1B[0m"
KRED="\x1B[31;1m"
KGRN="\x1B[32;1m"
KYEL="\x1B[33;1m"
KBLU="\x1B[34;1m"
KMAG="\x1B[35;1m"
KCYN="\x1B[36;1m"
KWHT="\x1B[37;1m"

for ((i=0;i<7;i++)); do

echo -e "${KYEL}0$i.pem TEST$KNRM"
./ft_ssl rsa -check -in 0$i.pem
echo -e "${KCYN}>>> ¿DIFF? <<<$KNRM"
openssl rsa -check -in 0$i.pem
echo -e "\n"

done
