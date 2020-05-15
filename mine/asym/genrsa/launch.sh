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
ls | grep -v launch.sh | xargs rm
exit
}


#>>>>> INPUT PARSER >>>>>

if [[ $1 != "genrsa" ]] || (( $# != 3 )); then
echo -e "${KYEL}usage: sh launch.sh genrsa numbits nb_tests${KNRM}"
exit
fi
# $2 : size of modulus in bits
numbits=$2
# $3 : numb of tests
nb_tests=$3
#<<<<< INPUT PARSER <<<<<<

#>>>>> TEST FUNCTIONS >>>>>>
err64="don't use key size < 64"

genrsa() {
./ft_ssl genrsa $numbits > rsak.pem
if (($? != 0));then echo -e "${KRED}${err64}${KNRM}"; ft_exit; fi
openssl rsa -check -in rsak.pem | grep ok >/dev/null
}

#>>>>>> MAIN >>>>>>
i=0
ok=0
col=$KYEL


while ((i < $nb_tests));do
genrsa 2>/dev/null

if (($? == 0)); then ((ok += 1)); fi
((i += 1))
if ((i != ok)); then col=$KRED; fi
echo -ne "									${col}genrsa:	${ok}/${nb_tests}${KNRM}"
echo -ne "\r"
done

if ((i == ok)); then col=$KGRN; fi
echo -e "									${col}genrsa:	${ok}/${nb_tests}${KNRM}"

#<<<<<< MAIN <<<<<<
ft_exit
