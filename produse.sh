#!/bin/bash

# Numele fisierului care contine lista de produse si preturi
FILE="produse.txt"

# Functie pentru a citi produsele si preturile din fisier
read_products() {
    mapfile -t products < "$FILE"
    for i in "${!products[@]}"; do
        products[i]=$(echo "${products[i]}" | tr -d '\r')
    done
}

# Functie pentru a afisa meniul produselor
display_products() {
    clear
    echo "=== Lista de produse ==="
    local columns=$(tput cols)
    local column_width=40
    local num_columns=$((columns / column_width))
    local num_rows=$(( (${#products[@]} + num_columns - 1) / num_columns ))

    for row in $(seq 0 $((num_rows - 1))); do
        for col in $(seq 0 $((num_columns - 1))); do
            index=$((row + col * num_rows))
            if [[ $index -lt ${#products[@]} ]]; then
                if [[ $index -eq $current_index ]]; then
                    # Evidentiem produsul selectat cu culori inversate
                    printf "\e[7m%02d. %-35s\e[0m" "$((index+1))" "${products[$index]}"
                else
                    printf "%02d. %-35s" "$((index+1))" "${products[$index]}"
                fi
            fi
        done
        echo ""
    done

    echo "========================================================="
    echo "Apasati 'a' pentru a adauga un produs, 'i' pentru a insera un produs, 'd' pentru a sterge un produs, 'q' pentru a iesi."
}

# Functie pentru a adauga un produs nou
add_product() {
    echo -n "Introduceti numele produsului: "
    read -r product_name
    product_name=$(echo "$product_name" | tr '[:lower:]' '[:upper:]')

    while true; do
        echo -n "Introduceti pretul produsului (numai cifre): "
        read -r product_price
        if [[ "$product_price" =~ ^[0-9]+$ ]]; then
            break
        else
            echo "Pret invalid. Va rugam introduceti numai cifre."
        fi
    done

    if [[ -n "$product_name" && -n "$product_price" ]]; then
        local new_product="$product_name:$product_price RON"
        if [[ -n "$1" ]]; then
            local index="$1"
            products=("${products[@]:0:$index}" "$new_product" "${products[@]:$index}")
        else
            products+=("$new_product")
        fi
        printf "%s\n" "${products[@]}" > "$FILE"
        read_products
        display_products
    else
        echo "Nume sau pret invalid. Produsul nu a fost adaugat."
    fi
}

# Functie pentru a sterge un produs
delete_product() {
    local index=$current_index
    unset 'products[index]'
    printf "%s\n" "${products[@]}" > "$FILE"
    read_products
}

# Initializam indexul curent
current_index=0

# Citim produsele din fisier
read_products

# Afisam meniul initial
display_products


# Bucla principala pentru a gestiona intrarile utilizatorului
while true; do
    read -rsn1 input
    case "$input" in
        $'\x1b') # Detectam tasta Esc
            read -rsn2 -t 0.1 input
            if [[ "$input" == "[A" ]]; then
                # Sageata sus
                ((current_index--))
                if [[ $current_index -lt 0 ]]; then
                    current_index=$(( ${#products[@]} - 1 ))
                fi
            elif [[ "$input" == "[B" ]]; then
                # Sageata jos
                ((current_index++))
                if [[ $current_index -ge ${#products[@]} ]]; then
                    current_index=0
                fi
            fi
            ;;
        [0-9]) # Detectam o cifra, pregatim sa citim a doua cifra
            read -rsn1 input2
            if [[ "$input2" =~ [0-9] ]]; then
                input+="$input2"
                if [[ "$input" =~ ^[0-9]{2}$ ]]; then
                    index=$((10#"$input" - 1))
                    if [[ $index -ge 0 && $index -lt ${#products[@]} ]]; then
                        current_index=$index
                    fi
                fi
            fi
            ;;
        a)
            add_product
            ;;
        i)
            add_product "$current_index"
            ;;
        d)
            delete_product
            ;;
        q)
            echo "Iesire..."
            break
            ;;
        *)
            echo "Optiune invalida!"
            ;;
    esac
    display_products
done

clear
echo "Program inchis."
