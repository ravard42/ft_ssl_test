#!/bin/bash

KNRM="\x1B[0m"
KRED="\x1B[31;1m"
KGRN="\x1B[32;1m"
KYEL="\x1B[33;1m"
KBLU="\x1B[34;1m"
KMAG="\x1B[35;1m"
KCYN="\x1B[36;1m"
KWHT="\x1B[37;1m"


#MAKING FT_SSL EXEC
make_dir="../../../"

echo -ne "${KYEL}ft_ssl makefile is running [...]$KNRM"
echo -ne "\r"
#make -C $make_dir  re > /dev/null 2>&1
make -C $make_dir
if (($? == 0));then
echo -e "${KGRN}ft_ssl successfully built and ready to be tested$KNRM\n"
else
echo -e "${KRED}error in ft_ssl compilation      $KNRM\n"
exit
fi
cp $make_dir/ft_ssl ./ 


#MESSAGE DIGEST TESTS

hash_cmd=("md5" "sha256")


for cmd in ${hash_cmd[@]};do
i=0
OK=0
COL=$KYEL

for file in $@;do
my_ssl=$(./ft_ssl $cmd $file)
openssl=$(openssl $cmd $file)
if [[ $my_ssl == $openssl ]];then
OK=$((OK + 1))
fi
i=$((i + 1))

if ((i != OK));then
COL=$KRED
fi
echo -ne "${COL}$cmd : ${OK}/$#${KNRM}"
echo -ne "\r"

done

if ((i == OK));then
COL=$KGRN
fi
echo -e "${COL}$cmd : ${OK}/$#${KNRM}"

done


#SYMMETRIC CIPHER TESTS

sym_cmd=("08k0_des-ecb" "08kv_des-cbc" "08kv_des-ofb" "08kv_des-cfb" 
		"24k0_des-ede3" "24kv_des-ede3-cbc" "24kv_des-ede3-ofb" "24kv_des-ede3-cfb")

rand_gen	() {
	if [[ $1 == "k" ]];then
	k=$(openssl rand -hex $2)
	elif [[ $1 == "v" ]];then
	v=$(openssl rand -hex $2)
	elif [[ $1 == "s" ]];then
	s=$(openssl rand -hex $2)
	fi
}

for cmd in ${sym_cmd[@]};do

i=0
OK=0
COL=$KYEL



for file in $@;do
rand_gen k $(echo ${cmd:0:2} | sed 's/^0*//')
rand_gen v 8
rand_gen s 8
if [[ ${cmd:3:1} == v ]];then
V="-v $v"
IV="-iv $v"
else
V=""
IV=""
fi

#K_V ENC TESTS
./ft_ssl ${cmd:5} -k $k $V -i $file -o my_ssl.enc -a
openssl ${cmd:5} -K $k $IV -in $file -out openssl.enc -a
diff my_ssl.enc openssl.enc
enc=$?

#K_V DEC TESTS
./ft_ssl ${cmd:5} -k $k $V -i my_ssl.enc -o my_ssl.dec -a -d
diff my_ssl.dec $file
dec=$?

#P_S ENC TESTS
p="toto"

./ft_ssl ${cmd:5} -p $p -s $s -i $file -o my_ssl.enc -a
openssl ${cmd:5} -pass pass:$p -S $s -in $file -out openssl.enc -a > /dev/null 2>&1
diff my_ssl.enc openssl.enc
enc_kdf=$?

#P_S DEC TESTS
./ft_ssl ${cmd:5} -p $p -i my_ssl.enc -o my_ssl.dec -a -d
diff my_ssl.dec $file
dec_kdf=$?

if (($enc == 0 && $dec == 0 && $enc_kdf == 0 && $dec_kdf == 0));then
OK=$((OK + 1))
fi
i=$((i + 1))

if ((i != OK));then
COL=$KRED
fi
echo -ne "${COL}${cmd:5} : ${OK}/$#${KNRM}"
echo -ne "\r"

done

if ((i == OK));then
COL=$KGRN
fi
echo -e "${COL}${cmd:5} : ${OK}/$#${KNRM}"

done

sh clear.sh
