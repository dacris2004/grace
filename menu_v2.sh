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

# Functie pentru a extrage pretul dintr-un produs
get_price() {
    [[ $1 ]] && {
        local product_entry="$1"
        echo "$product_entry" | awk -F: '{print $2}' | awk -F\  '{print $1}'
    } || echo "0"
}

# Functie pentru afisare cos si total
display_cos() {
    echo ""
    echo "=== Cosul de Cumparaturi ==="
    total="0"
    for product in "${!cart[@]}"; do
        quantity="${cart[$product]}"
        price=$(get_price "$product")
        total=$(echo "$total + $price * $quantity" | bc)
        echo "$product ($quantity)"
    done
    printf "Total: %.2f RON\n" "$total"
    echo ""
}

# Functie pentru a afisa meniul si cosul in coloane
display_menu() {
    clear
    echo "=== Meniu Produse ==="
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

    display_cos
    
    echo "Apasati sagetile sus/jos pentru a naviga, Enter pentru a adauga/scoate din cos."
    echo "Apasati doua cifre pentru a adauga/scoate produsul."
    echo "Apasati '+' pentru a adauga cantitate."
    echo "Apasati '-' pentru a scadea cantitate."
    echo "Apasati 'p' pentru a tipari cosul la casa de marcat."
    echo "Apasati 'x' pentru anulare cos de cumparaturi."
    echo "Apasati 'q' pentru a iesi."
}

# Initializam cosul de cumparaturi si indexul curent
declare -A cart
current_index=0

# Citim produsele din fisier
read_products

# Afisam meniul initial
display_menu

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
        '') # Detectam tasta Enter
            product="${products[$current_index]}"
            product_entry="$(printf "%02d. %s" "$((current_index+1))" "$product")"
            if [[ -n "${cart[$product_entry]}" ]]; then
                # Scoatem produsul din cos
                unset cart["$product_entry"]
            else
                # Adaugam produsul in cos
                cart["$product_entry"]=1
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
                        product="${products[$index]}"
                        product_entry="$(printf "%02d. %s" "$((index+1))" "$product")"
                        if [[ -n "${cart[$product_entry]}" ]]; then
                            # Scoatem produsul din cos
                            unset cart["$product_entry"]
                        else
                            # Adaugam produsul in cos
                            cart["$product_entry"]=1
                        fi
                    fi
                fi
            fi
            ;;
        '+') # Adauga cantitate
            product="${products[$current_index]}"
            product_entry="$(printf "%02d. %s" "$((current_index+1))" "$product")"
            if [[ -n "${cart[$product_entry]}" ]]; then
                cart["$product_entry"]=$((cart["$product_entry"] + 1))
            else
                cart["$product_entry"]=1
            fi
            ;;
        '-') # Scade cantitate
            product="${products[$current_index]}"
            product_entry="$(printf "%02d. %s" "$((current_index+1))" "$product")"
            if [[ -n "${cart[$product_entry]}" ]]; then
                if [[ ${cart[$product_entry]} -gt 1 ]]; then
                    cart["$product_entry"]=$((cart["$product_entry"] - 1))
                else
                    unset cart["$product_entry"]
                fi
            fi
            ;;
	'x') #anulare cos
	    clear
	    cart=()
	    display_cos
            ;;
		
        p) # Tiparim cosul
            clear
            display_cos
            echo "============================="
            echo "Apasati orice tasta pentru a reveni la meniu."
            read -rsn1
	    cart=()
            ;;
        q) # Iesim din program
            break
            ;;
    esac
    display_menu
done

clear
echo "Program inchis."
