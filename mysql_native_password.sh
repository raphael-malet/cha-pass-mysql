#!/bin/bash

# Variables définies à partir des arguments de ligne de commande
password=$1
salt=$2

# Vérification que le script a bien reçu les deux arguments
if [ -z "$password" ] || [ -z "$salt" ]; then
    echo "Usage: $0 <password> <salt>"
    exit 1
fi

# Calcul de SHA1(password)
sha_password=$(echo -n "$password" | openssl sha1 | awk '{print $2}')
echo "Premier SHA-1 (SHA1(password)) : $sha_password"

# Calcul de SHA1(SHA1(password))
sha_sha_password=$(echo -n "$sha_password" | openssl sha1 | awk '{print $2}')
echo "Deuxième SHA-1 (SHA1(SHA1(password))) : $sha_sha_password"

# Ajout du salt et calcul de SHA1(s + SHA1(SHA1(password)))
salt_sha_sha_password="$salt$sha_sha_password"
sha_salt_sha_sha_password=$(echo -n "$salt_sha_sha_password" | openssl sha1 | awk '{print $2}')
echo "SHA-1(salt + SHA1(SHA1(password))) : $sha_salt_sha_sha_password"

# Fonction pour convertir une chaîne hexadécimale en décimal
hex_to_dec() {
    echo $((16#$1))
}

# Effectuer l'opération XOR entre SHA1(password) et SHA1(s + SHA1(SHA1(password)))
xor_result=""
for (( i=0; i<${#sha_password}; i+=2 )); do
    # Extraire deux caractères de chaque chaîne (1 octet)
    byte1=${sha_password:i:2}
    byte2=${sha_salt_sha_sha_password:i:2}

    # Convertir les octets en décimal, effectuer le XOR et reconvertir en hexadécimal
    xor_byte=$(printf "%02x" $(( $(hex_to_dec $byte1) ^ $(hex_to_dec $byte2) )))

    # Ajouter le résultat à la chaîne finale
    xor_result="$xor_result$xor_byte"
done

# Afficher le résultat final
echo "Résultat du XOR : $xor_result"

# Calcul de SHA1(x XOR SHA1(s + SHA1(SHA1(password))))
sha_xor_result=$(echo -n "$xor_result" | openssl sha1 | awk '{print $2}')
echo "SHA1(x XOR SHA1(s + SHA1(SHA1(password)))) : $sha_xor_result"

# Vérification de la condition : SHA1(x XOR ...) == SHA1(SHA1(password))
if [ "$sha_xor_result" == "$sha_sha_password" ]; then
    echo "La condition est vérifiée : SHA1(x XOR SHA1(s + SHA1(SHA1(password)))) = SHA1(SHA1(password))"
else
    echo "La condition n'est pas vérifiée."
fi

sha_xor_result=$(echo -n "$xor_result" | openssl sha1 | awk '{print $2}')

if [ "$sha_xor_result" == "$sha_sha_password" ]; then
    echo "La condition est vérifiée ..."
else
    echo "La condition n'est pas vérifiée."
fi
