#!/bin/bash

#NEW test_script_archi cf function_args.sh in ~/language/scriptShell/learning-bash

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
# available tests
# no padding enc
test_type[0]='expmod_raw_enc'
test_nbarg[0]=3
test_usage[0]='sh launch.sh expmod_raw_enc key_len nb_tests'
# no padding pipe enc dec
test_type[1]='expmod_raw_encdec'
test_nbarg[1]=3
test_usage[1]='sh launch.sh expmod_raw_encdec key_len nb_tests'
# PKCS#1 v1.5 padding pipe enc(square-and-multiply) dec(Chinese remainder algorithm based on the CRT)
test_type[2]='expmod_pad_encdec'
test_nbarg[2]=3
test_usage[2]='sh launch.sh expmod_pad_encdec key_len nb_tests'

nb_type=3
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

if (( test_nbarg[id] != $# )); then
echo -e "${KYEL}${test_usage[$id]}$KRNM"
ft_exit
fi

#<<<<< INPUT PARSER <<<<<<

#>>>>> TEST FUNCTIONS >>>>>>
err64="don't use key size < 64"
err512="don't use key size < 512"

expmod_raw_enc() {
key_bit_len=$2
key_byte_len=$((1 + (key_bit_len - 1) / 8))
#./ft_ssl genrsa -out key.pem $key_bit_len 
#if (($? != 0));then echo -e "${KRED}${err64}${KNRM}"; ft_exit; fi
openssl genrsa -out key.pem $key_bit_len 2>/dev/null
if (($? != 0));then echo -e "${KRED}${err512}${KNRM}"; ft_exit; fi

echo -ne "\x00" > data.ref
data_byte_len=$((key_byte_len - 1))
head -c $data_byte_len /dev/urandom >> data.ref


./ft_ssl rsautl -in data.ref -inkey key.pem -encrypt -raw -out data_enc.ft_ssl
openssl rsautl -in data.ref -inkey key.pem -encrypt -raw -out data_enc.openssl
diff data_enc.ft_ssl data_enc.openssl >/dev/null 2>&1

}

expmod_raw_encdec() {
key_bit_len=$2
key_byte_len=$((1 + (key_bit_len - 1) / 8))
#./ft_ssl genrsa -out key.pem $key_bit_len 
#if (($? != 0));then echo -e "${KRED}${err64}${KNRM}"; ft_exit; fi
openssl genrsa -out key.pem $key_bit_len 2>/dev/null
if (($? != 0));then echo -e "${KRED}${err512}${KNRM}"; ft_exit; fi

echo -ne "\x00" > data.ref
data_byte_len=$((key_byte_len - 1))
head -c $data_byte_len /dev/urandom >> data.ref

./ft_ssl rsautl -in data.ref -inkey key.pem -encrypt -raw  | ./ft_ssl rsautl -inkey key.pem -decrypt -raw -out data.ft_ssl
diff data.ref data.ft_ssl >/dev/null 2>&1

}

expmod_pad_encdec() {
key_bit_len=$2
key_byte_len=$((1 + (key_bit_len - 1) / 8))
echo -e "${KYEL}(key_bit_len, key_byte_len) = ($key_bit_len, $key_byte_len)$KNRM"
if ((key_byte_len < 11)); then
echo -e "${KRED}key_byte_len must be >= 11$KNRM"
ft_exit
fi
#./ft_ssl genrsa -out key.pem $key_bit_len 
#if (($? != 0));then echo -e "${KRED}${err64}${KNRM}"; ft_exit; fi
openssl genrsa -out key.pem $key_bit_len 2>/dev/null
if (($? != 0));then echo -e "${KRED}${err512}${KNRM}"; ft_exit; fi

data_byte_len=$((RANDOM % (key_byte_len - 11 + 1)))
echo -e "${KCYN}data_byte_len = $data_byte_len ---> randomely chosen to be at least 11 byte smaller than key_byte_len$KNRM"
head -c $data_byte_len /dev/urandom > data.ref

./ft_ssl rsautl -in data.ref -inkey key.pem -encrypt  | ./ft_ssl rsautl -inkey key.pem -decrypt -out data.ft_ssl
diff data.ref data.ft_ssl >/dev/null 2>&1

}

#<<<<< TESTS FUNCTIONS <<<<<<

#>>>>>> MAIN >>>>>>
i=0
ok=0
col=$KYEL
nb_tests=${@: -1}

while ((i < nb_tests)); do
	${test_type[$id]} "$@" 2>/dev/null

if (($? == 0)); then ((ok += 1)); fi
((i += 1))
if ((i != ok)); then col=$KRED; fi
echo -ne "									${col}${test_type[$id]}:	${ok}/${nb_tests}${KNRM}"
echo -ne "\r"
done

if ((i == ok)); then col=$KGRN; fi
echo -e "									${col}${test_type[$id]}:	${ok}/${nb_tests}${KNRM}"
#<<<<<< MAIN <<<<<<

ft_exit
