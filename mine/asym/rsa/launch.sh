#!/bin/bash

KNRM="\x1B[0m"
KRED="\x1B[31;1m"
KGRN="\x1B[32;1m"
KYEL="\x1B[33;1m"
KBLU="\x1B[34;1m"
KMAG="\x1B[35;1m"
KCYN="\x1B[36;1m"
KWHT="\x1B[37;1m"


#>>>> MAKING ./FT_SSL >>>>>
make_dir="../../../../"

echo -ne "${KYEL}ft_ssl makefile is running [...]$KNRM"
echo -ne "\r"
#make -C $make_dir  re > /dev/null 2>&1
#make -C $make_dir  re
make -C $make_dir  
if (($? == 0));then
echo -e "${KGRN}ft_ssl successfully built and ready to be tested$KNRM\n"
else
echo -e "${KRED}error in ft_ssl compilation      $KNRM\n"
fi

cp $make_dir/ft_ssl ./ 
#<<<< MAKING ./FT_SSL <<<<<<

ft_exit ()
{
ls | grep -v launch.sh | xargs rm 2>/dev/null
exit
}


#>>>>> INPUT PARSER >>>>>
# available tests
test_type[0]='rsa_inprider'
test_type[1]='rsa_inpripem'
test_type[2]='rsa_inprienc'
test_type[3]='rsa_inpubder'
test_type[4]='rsa_inpubpem'
test_type[5]='rsa_pipepubder'
test_type[6]='rsa_pipepubpem'
test_type[7]='rsa_pipeprider'
test_type[8]='rsa_pipepripem'
test_type[9]='rsa_desout'
test_type[10]='rsa_check'
test_type[11]='rsa_full'
nb_type=12
# $1 : type of the test
for ((id = 0; id < nb_type; ++id)); do
if [[ $1 == ${test_type[$id]} ]]; then break; fi
done

if (( id == nb_type )); then
echo -ne "${KYEL}usage: sh launch.sh "
for ((i = 0; i < nb_type - 1; i++ )); do echo -n "${test_type[$i]}|"; done
echo -e "${test_type[$i]}$KRNM"
ft_exit
fi

if (( $# != 3 )); then
echo -e "${KYEL}usage: sh launch.sh ${test_type[$id]} numbits numberOfTests\n$KRNM"
ft_exit
fi

# $2 : size of modulus in bits
numbits=$2
# $3 : numb of tests
nb_tests=$3
#<<<<< INPUT PARSER <<<<<<

#>>>>> TEST FUNCTIONS >>>>>>

err512="don't use key size < 512"

rsa_inprider() {
openssl genrsa $numbits | openssl rsa -outform DER -out prider.ref
if (($? != 0));then echo -e "${KRED}${err512}${KNRM}"; ft_exit; fi

openssl rsa -in prider.ref -inform DER -text -noout > text.openssl
./ft_ssl rsa -in prider.ref -inform DER -text -noout > text.ft_ssl


diff text.openssl text.ft_ssl
}

rsa_inpripem() {
openssl genrsa -out pripem.ref $numbits
if (($? != 0));then echo -e "${KRED}${err512}${KNRM}"; ft_exit; fi

openssl rsa -in pripem.ref -text -modulus -noout > text.openssl
./ft_ssl rsa -in pripem.ref -text -modulus -noout > text.ft_ssl

diff text.openssl text.ft_ssl
}

rsa_inprienc() {
pw="4charmin$RANDOM"
openssl genrsa $numbits | openssl rsa -des -passout pass:$pw -out prienc.ref
if (($? != 0));then echo -e "${KRED}${err512}${KNRM}"; ft_exit; fi

openssl rsa -in prienc.ref -passin pass:$pw  -text -noout > text.openssl
./ft_ssl rsa -in prienc.ref -passin pass:$pw  -text -noout > text.ft_ssl

diff text.openssl text.ft_ssl
}

rsa_inpubder() {
openssl genrsa $numbits | openssl rsa -outform DER -pubout -out pubder.ref
if (($? != 0));then echo -e "${KRED}${err512}${KNRM}"; ft_exit; fi

openssl rsa -in pubder.ref -inform DER -pubin -text -noout > text.openssl
./ft_ssl rsa -in pubder.ref -inform DER -pubin -text -noout > text.ft_ssl

diff text.openssl text.ft_ssl
}

rsa_inpubpem() {
openssl genrsa $numbits | openssl rsa -pubout -out pubpem.ref
if (($? != 0));then echo -e "${KRED}${err512}${KNRM}"; ft_exit; fi

openssl rsa -in pubpem.ref -pubin -text -modulus -noout > text.openssl
./ft_ssl rsa -in pubpem.ref -pubin -text -modulus -noout > text.ft_ssl

diff text.openssl text.ft_ssl
}

rsa_pipepubder() {
openssl genrsa -out pripem.ref $numbits
if (($? != 0));then echo -e "${KRED}${err512}${KNRM}"; ft_exit; fi

openssl rsa -in pripem.ref -pubout -outform DER -out pubder.ref
./ft_ssl rsa -pubin -inform DER -in pubder.ref -pubout -outform DER -out pubder.ft_ssl
# PRIV IN
#./ft_ssl rsa -in pripem.ref -pubout -outform DER -out pubder.ft_ssl

diff pubder.ref pubder.ft_ssl
}

rsa_pipepubpem() {
openssl genrsa -out pripem.ref $numbits
if (($? != 0));then echo -e "${KRED}${err512}${KNRM}"; ft_exit; fi
openssl rsa -in pripem.ref -pubout -out pubpem.ref

./ft_ssl rsa -pubin -in pubpem.ref -pubout -out pubpem.ft_ssl
# PRIV IN
#./ft_ssl rsa -in pripem.ref -pubout -out pubpem.ft_ssl

diff pubpem.ref pubpem.ft_ssl
}

rsa_pipeprider() {
openssl genrsa $numbits | openssl rsa -outform DER -out prider.ref
if (($? != 0));then echo -e "${KRED}${err512}${KNRM}"; ft_exit; fi

./ft_ssl rsa -inform DER -in prider.ref -outform DER -out prider.ft_ssl

diff prider.ref prider.ft_ssl
}

rsa_pipepripem() {
openssl genrsa -out pripem.ref $numbits
if (($? != 0));then echo -e "${KRED}${err512}${KNRM}"; ft_exit; fi

./ft_ssl rsa -in pripem.ref -out pripem.ft_ssl

diff pripem.ref pripem.ft_ssl
}


rsa_desout() {
openssl genrsa -out pripem.ref $numbits
if (($? != 0));then echo -e "${KRED}${err512}${KNRM}"; ft_exit; fi

pw="4charmin$RANDOM"
./ft_ssl rsa -in pripem.ref -des -passout pass:$pw | openssl rsa -passin pass:$pw -out pripem.ft_ssl

diff pripem.ref pripem.ft_ssl
}

rsa_check() {
openssl genrsa -out pripem.ref $numbits
if (($? != 0));then echo -e "${KRED}${err512}${KNRM}"; ft_exit; fi

./ft_ssl rsa -in pripem.ref -check -noout | grep ok > /dev/null

}

rsa_full() {
for ((j = 0; j < $nb_type - 1; ++j));do
sh launch.sh ${test_type[$j]} $numbits $nb_tests
done
ft_exit
}

#<<<<< TEST FUNCTIONS <<<<<<


#>>>>>> MAIN >>>>>>
i=0
ok=0
col=$KYEL


while ((i < $nb_tests));do
${test_type[$id]} 2>/dev/null

if (($? == 0)); then ((ok += 1)); fi
((i += 1))
if ((i != ok)); then col=$KRED; fi
echo -ne "									${col}${test_type[$id]}:	${ok}/${nb_tests}${KNRM}"
echo -ne "\r"
done

if ((i == ok)); then col=$KGRN; fi
echo -e "									${col}${test_type[$id]}:	${ok}/${nb_tests}${KNRM}"

#<<<<<< MAIN <<<<<<
